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
#
# 0004-reference-data.sql is NOT vendored either, and that is a change from when
# this script was written. The chart's copy is no longer upstream's: it has been
# extended here across several commits with the estimators, parameters,
# parameter_map, period_types, location_kinds and parameter_class_limits rows a
# deployment needs, and is now ~117 KB against upstream's ~1.4 KB, which still
# holds target_types alone. Listing it here would silently overwrite all of that
# with the smaller upstream file on the next sync. If the two are ever
# reconciled, upstream has to win first, then this entry can come back.
FILES=(
  0000-pre-init.sql
  0001-production-schema.sql
  0002-post-ownership.sql
)

# Normalise a generated pg_dump for vendoring: drop its comment banners and
# trailing whitespace.
#
# Two separate reasons, both about the rendered ConfigMap rather than the SQL:
#
#   * About 36% of 0001-production-schema.sql is pg_dump's own
#     "-- Name: <object>; Type: <kind>" banners. The database needs none of it,
#     and it pushes the ConfigMap to roughly 67% of the 1 MiB object limit.
#   * A line with trailing whitespace makes Helm's YAML emitter abandon the
#     literal block scalar and quote the whole file as one line. A faithful
#     production dump has 17 such lines: 4 are "Owner: " banners removed by the
#     comment strip, and 13 sit between tokens inside function bodies, where
#     PostgreSQL stored the whitespace as part of prosrc.
#
# This runs here rather than upstream on purpose. fmi-verification-common-sql
# keeps a byte-faithful dump that tools/split-dump.awk can still split on those
# banners; only the vendored copy is normalised.
#
# Comments are removed only at column 1 and only outside a dollar-quoted body,
# so function bodies are never rewritten. A full-line comment is never scanned
# for dollar-quote tokens, so a comment containing '$$' cannot flip the state.
#
# Trailing whitespace is trimmed everywhere. In the current dump every such line
# ends outside any string literal, so only inter-token space is lost. A value
# whose meaningful trailing space fell at a line end inside a multi-line literal
# would be altered; no such value exists today, and the checks below re-assert
# the post-condition.
normalize_dump() {
  local file="$1" tmp before after body_before body_after
  before=$(wc -c < "${file}" | tr -d ' ')
  body_before=$(grep -c -v '^--' "${file}" || true)
  tmp="$(mktemp)"

  awk '
    {
      if (dq == "" && substr($0, 1, 2) == "--") next
      s = $0
      while (match(s, /\$[A-Za-z_][A-Za-z0-9_]*\$|\$\$/)) {
        tok = substr(s, RSTART, RLENGTH)
        if (dq == "") dq = tok
        else if (tok == dq) dq = ""
        s = substr(s, RSTART + RLENGTH)
      }
      sub(/[ \t]+$/, "")
      print
    }
    END {
      if (dq != "") {
        print "unbalanced dollar quoting; refusing to normalise" > "/dev/stderr"
        exit 1
      }
    }
  ' "${file}" > "${tmp}" || {
    echo "ERROR: ${file}: normalisation failed" >&2; rm -f "${tmp}"; exit 1
  }

  # The strip must only ever drop '--' lines. If any other line disappeared, the
  # dollar-quote tracking went wrong and the output cannot be trusted.
  body_after=$(grep -c -v '^--' "${tmp}" || true)
  if [[ "${body_before}" -ne "${body_after}" ]]; then
    echo "ERROR: ${file}: normalisation changed non-comment line count (${body_before} -> ${body_after})" >&2
    rm -f "${tmp}"; exit 1
  fi

  # Overwrite in place rather than mv, so the mktemp 0600 mode is not inherited.
  cat "${tmp}" > "${file}"
  rm -f "${tmp}"
  after=$(wc -c < "${file}" | tr -d ' ')
  printf '  normalised (%s B -> %s B, -%s%%)\n' \
    "${before}" "${after}" "$(( 100 * (before - after) / before ))"
}

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

  # Only the generated dump is stripped. The other three files are
  # hand-maintained and their comments are documentation.
  if [[ "${f}" == "0001-production-schema.sql" ]]; then
    normalize_dump "${SQL_DIR}/${f}"
  fi

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
