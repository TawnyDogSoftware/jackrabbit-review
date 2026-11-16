#!/bin/bash
# Render the verification prompts for a merged review.
# usage: verify-batches.sh <run-dir> [<findings-per-batch>]
# Reads <run-dir>/merged.md, counts its "### F<n>." headings, and writes one prompt per batch.
# Each line ends with the model the verifiers run on, as chosen with prepare.sh --model.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
run=$1; size=${2:-14}
[ -s "$run/merged.md" ] || { echo "no merged review at $run/merged.md" >&2; exit 2; }
total=$(grep -cE '^### F[0-9]+\.' "$run/merged.md" || true)
[ "$total" -gt 0 ] || { echo "merged review has no '### F<n>.' headings; findings: 0" ; exit 0; }
repo=$(cat "$run/repo"); base=$(cat "$run/base"); diff_cmd=$(cat "$run/diff_cmd")
model=$(awk '$1 == "verify" { print $2 }' "$run/models" 2>/dev/null || true); model=${model:-default}
batches=$(( (total + size - 1) / size ))
per=$(( (total + batches - 1) / batches ))
echo "findings: $total, batches: $batches"
n=1; first=1
while [ "$first" -le "$total" ]; do
  last=$(( first + per - 1 )); [ "$last" -gt "$total" ] && last=$total
  text=$(cat "$here/prompts/verify.md")
  text=${text//'{{REPO_PATH}}'/$repo}
  text=${text//'{{DIFF_CMD}}'/$diff_cmd}
  text=${text//'{{BASE}}'/$base}
  text=${text//'{{REVIEW}}'/$run/merged.md}
  text=${text//'{{RANGE}}'/F$first to F$last}
  text=${text//'{{OUT}}'/$run/verdicts-$n.md}
  printf '%s\n' "$text" > "$run/prompt-verify-$n.md"
  echo "verifier $n (F$first to F$last): prompt $run/prompt-verify-$n.md -> $run/verdicts-$n.md | model $model"
  first=$(( last + 1 )); n=$(( n + 1 ))
done
