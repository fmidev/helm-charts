#!/usr/bin/env bash
#
# Vendor the SmartMet Verify SQL schema into files/sql/.
#
# The upstream repo (fmidev/fmi-verification-common-sql) is private and has no
# tags or releases, so the schema is pinned by commit SHA. The pin lives in
# Chart.yaml under the annotation fmi.fi/verification-sql-ref and is the single
# source of truth: this script reads it and writes it back.
#
# Requires: gh (authenticated, with access to the private upstream repo).
#
# Usage:
#   scripts/sync-schema.sh              # re-fetch the ref currently pinned
#   scripts/sync-schema.sh <git-ref>    # move the pin to <git-ref> and fetch
#   scripts/sync-schema.sh main         # move the pin to upstream HEAD
#
set -euo pipefail

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_YAML="${CHART_DIR}/Chart.yaml"
SQL_DIR="${CHART_DIR}/files/sql"
REPO="fmidev/fmi-verification-common-sql"
ANNOTATION="fmi.fi/verification-sql-ref"

# 0003-legacy-test-data.sql is intentionally NOT vendored: it is nothing but
# \COPY meta-commands against ~176 MB of CSV fixtures. CNPG cannot execute psql
# meta-commands, and the fixtures have no place in a chart.
FILES=(
  0000-pre-init.sql
  0001-production-schema.sql
  0002-post-ownership.sql
)

command -v gh >/dev/null || { echo "ERROR: gh is required" >&2; exit 1; }

current_ref() {
  sed -n "s|^[[:space:]]*${ANNOTATION}:[[:space:]]*\"\{0,1\}\([0-9a-f]\{7,40\}\)\"\{0,1\}[[:space:]]*$|\1|p" \
    "${CHART_YAML}" | head -1
}

REF="${1:-$(current_ref)}"
[[ -n "${REF}" ]] || { echo "ERROR: no ref given and none pinned in Chart.yaml" >&2; exit 1; }

echo "Resolving ${REPO}@${REF} ..."
SHA="$(gh api "repos/${REPO}/commits/${REF}" --jq .sha)"
echo "  -> ${SHA}"

mkdir -p "${SQL_DIR}"
for f in "${FILES[@]}"; do
  echo "Fetching ${f} ..."
  # Use the raw media type rather than --jq .content: the Contents API refuses
  # to inline `content` for files over 1 MB, and the dump is already at ~67%.
  gh api "repos/${REPO}/contents/${f}?ref=${SHA}" \
     -H 'Accept: application/vnd.github.raw' > "${SQL_DIR}/${f}"

  # These four checks are load-bearing, not hygiene. A CR byte, a trailing
  # space, or invalid UTF-8 makes Helm's YAML emitter abandon the literal block
  # scalar and emit the whole ~686 KB file as ONE quoted line, which is both
  # unreviewable and liable to trip object-size limits. A leading backslash
  # means a psql meta-command, which CNPG cannot execute at all.
  if LC_ALL=C grep -q $'\r' "${SQL_DIR}/${f}"; then
    echo "ERROR: ${f} contains CR bytes; would force quoted YAML" >&2; exit 1
  fi
  if grep -q '[[:space:]]$' "${SQL_DIR}/${f}"; then
    echo "ERROR: ${f} has trailing whitespace; would force quoted YAML" >&2; exit 1
  fi
  if ! iconv -f UTF-8 -t UTF-8 "${SQL_DIR}/${f}" >/dev/null 2>&1; then
    echo "ERROR: ${f} is not valid UTF-8; would force quoted YAML" >&2; exit 1
  fi
  if grep -q '^\\' "${SQL_DIR}/${f}"; then
    echo "ERROR: ${f} contains psql meta-commands; CNPG cannot execute them" >&2; exit 1
  fi

  size=$(wc -c < "${SQL_DIR}/${f}" | tr -d ' ')
  if [[ "${size}" -gt 1000000 ]]; then
    echo "ERROR: ${f} is ${size} B, too close to the 1 MiB ConfigMap limit" >&2; exit 1
  fi
  printf '  ok (%s B)\n' "${size}"
done

# Write the resolved SHA back, preserving the quoting style.
tmp="$(mktemp)"
sed "s|^\([[:space:]]*${ANNOTATION}:[[:space:]]*\).*$|\1\"${SHA}\"|" "${CHART_YAML}" > "${tmp}"
mv "${tmp}" "${CHART_YAML}"

cat <<EOF

Pinned ${REPO}@${SHA}

Next steps:
  1. Review the diff under files/sql/.
  2. Bump 'version' in Chart.yaml (ct lint enforces an increment).
  3. Remember the schema applies at initdb ONLY -- existing databases are NOT
     migrated by upgrading this chart.
EOF
