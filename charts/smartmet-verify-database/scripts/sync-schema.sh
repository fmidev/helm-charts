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
# 0004-reference-data.sql is intentionally NOT synced either, and that is easy to
# get wrong: upstream has a file of the same name, so the sync looks like it
# would work. It would overwrite. Upstream's copy is the original ~1.4 kB
# target_types seed; this chart's has grown past 120 kB with the estimators,
# parameters, class limits, parameter_map categories, period types, location
# kinds and localization a deployment needs. The two are not versions of one
# file -- they are different files that share a name. Fetching upstream's over
# this one silently discards all of it, and the only thing standing in the way
# is remembering to read the diff.
FILES=(
  0000-pre-init.sql
  0001-production-schema.sql
  0002-post-ownership.sql
)

command -v gh >/dev/null || { echo "ERROR: gh is required" >&2; exit 1; }

# Strip pg_dump's own banners out of the schema dump.
#
# pg_dump wraps every object in a three-line "-- Name: ...; Type: ...; Owner:"
# banner. Across ~2 700 objects that is 251 KB -- 37% of the file -- and it is
# read by nothing: CloudNativePG hands this straight to the server as SQL. The
# saving takes the production ConfigMap from 65% of the 1 MiB object limit to
# 41%, which is the difference between watching that number and not.
#
# Three deliberate exceptions, each of which has a reason to exist:
#
#   - dollar-quote aware. A PL/pgSQL body may contain a line starting with
#     "--", and deleting it would rewrite the function's stored source.
#   - blank runs are collapsed only OUTSIDE a body, for the same reason. Doing
#     it inside leaves every catalog identical while making pg_dump's output
#     differ, which is exactly the kind of silent drift a schema comparison
#     later reports as a real change. This was observed and fixed, not
#     theorised.
#   - "Intentionally commented out" annotations are kept, along with the line
#     they annotate. They record why pg_partman is absent and carry the
#     statement someone would re-enable.
#
# COMMENT ON statements are untouched: they do not begin with "--" and they are
# schema content rather than commentary about it.
#
# Trailing whitespace is trimmed everywhere, and every line trimmed INSIDE a
# function body is printed. Inside a body that whitespace is part of prosrc, so
# the rewrite is real and must be visible -- but refusing outright is wrong too:
# upstream's dump carries such lines, they sit at end of line outside any string
# literal, and PostgreSQL keeps them only because whoever wrote the function left
# them there. What must not happen is trimming them without saying so, which is
# why each one is named.
#
# The check that this changed no token is not in this awk at all: it is the
# whitespace-insensitive prosrc comparison in the equivalence test, which is
# mechanical where a regex would be a guess.
normalize_dump() {
  awk '
    BEGIN { depth = 0; keep_next = 0; blank_run = 0 }
    {
      line = $0
      inside = (depth > 0)

      if (!inside && line ~ /^--/) {
        if (line ~ /Intentionally commented out/) { print line; keep_next = 1; blank_run = 0; next }
        if (keep_next)                            { print line; keep_next = 0; blank_run = 0; next }
        removed++
        next
      }
      keep_next = 0

      if (line ~ /[ \t]+$/) {
        if (inside) {
          printf("  trimmed inside a function body, line %d: %s\n", NR, line) > "/dev/stderr"
          ws_inside++
        }
        sub(/[ \t]+$/, "", line)
        ws_trimmed++
      }

      if (line ~ /^$/) {
        if (!inside) { blank_run++; if (blank_run > 1) { collapsed++; next } }
      } else {
        blank_run = 0
      }

      print line
      kept++

      n = gsub(/\$[A-Za-z_0-9]*\$/, "&", $0)
      if (n > 0) depth = (depth + n) % 2
    }
    END {
      printf("  normalised: -%d comment lines, -%d blank lines, %d trailing trimmed, %d kept\n",
             removed, collapsed, ws_trimmed, kept) > "/dev/stderr"
      if (depth != 0) {
        print "ERROR: unbalanced dollar quoting after normalising" > "/dev/stderr"; exit 1
      }
      if (ws_inside > 0) {
        printf("  NOTE: %d of those were inside a function body, listed above\n",
               ws_inside) > "/dev/stderr"
      }
    }
  ' "$1"
}

# Every statement must survive the strip. Comparing the count of lines that are
# neither a banner nor blank catches a dollar-quote mis-track, which is the only
# way the awk above could eat something it should not have.
statement_lines() {
  grep -cvE '^--|^[[:space:]]*$' "$1"
}

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
  # to inline `content` for files over 1 MB, and the dump is close enough to
  # that even after normalising.
  gh api "repos/${REPO}/contents/${f}?ref=${SHA}" \
     -H 'Accept: application/vnd.github.raw' > "${SQL_DIR}/${f}"

  # Only the schema dump. 0000, 0002 and 0004 are hand-maintained and their
  # comments are documentation of why each statement is there.
  if [[ "${f}" == 0001-* ]]; then
    before_stmts="$(statement_lines "${SQL_DIR}/${f}")"
    before_bytes="$(wc -c < "${SQL_DIR}/${f}" | tr -d ' ')"
    tmp_norm="$(mktemp)"
    if ! normalize_dump "${SQL_DIR}/${f}" > "${tmp_norm}"; then
      rm -f "${tmp_norm}"
      echo "ERROR: normalising ${f} failed" >&2; exit 1
    fi
    after_stmts="$(statement_lines "${tmp_norm}")"
    if [[ "${before_stmts}" -ne "${after_stmts}" ]]; then
      rm -f "${tmp_norm}"
      echo "ERROR: ${f} lost content while normalising (${before_stmts} -> ${after_stmts} statement lines)" >&2
      exit 1
    fi
    mv "${tmp_norm}" "${SQL_DIR}/${f}"
    printf '  %s B -> %s B\n' "${before_bytes}" "$(wc -c < "${SQL_DIR}/${f}" | tr -d ' ')"
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
  # 1 MiB is 1 048 576 B and the limit is on the summed values of the whole
  # ConfigMap, so a file allowed right up to 1 000 000 B leaves no room for the
  # key or anything else in the object.
  if [[ "${size}" -gt 900000 ]]; then
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
