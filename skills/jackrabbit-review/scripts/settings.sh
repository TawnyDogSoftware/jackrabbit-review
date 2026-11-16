#!/bin/bash
# Print the jackrabbit-review settings that apply in the current repository, and where each
# one comes from. Later files override earlier ones:
#   <skill dir>/jackrabbit-review-config.yaml                    defaults shipped with the skill
#   ${XDG_CONFIG_HOME:-~/.config}/jackrabbit-review-config.yaml  the user's settings
#   <repository root>/jackrabbit-review-config.yaml              the repository's settings
# Each file holds "key: value" lines; "#" starts a comment. Keys: serial, include_uncommitted,
# base, models. Output: one "key: value | from <file>" line per key ("default" when no file sets it).
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
keys="serial include_uncommitted base models"
declare -A val src
for k in $keys; do val[$k]=""; src[$k]=default; done
val[serial]=false; val[include_uncommitted]=false

files=("$here/jackrabbit-review-config.yaml" "${XDG_CONFIG_HOME:-$HOME/.config}/jackrabbit-review-config.yaml")
if top=$(git rev-parse --show-toplevel 2>/dev/null); then files+=("$top/jackrabbit-review-config.yaml"); fi

for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  n=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    line=${line%%#*}
    [[ $line =~ ^[[:space:]]*$ ]] && continue
    if ! [[ $line =~ ^[[:space:]]*([A-Za-z_-]+)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
      echo "warning: $f:$n: cannot read this line; write key: value" >&2; continue
    fi
    k=${BASH_REMATCH[1]//-/_}; v=${BASH_REMATCH[2]}
    v="${v%"${v##*[![:space:]]}"}"
    [[ $v =~ ^\"(.*)\"$ || $v =~ ^\'(.*)\'$ ]] && v=${BASH_REMATCH[1]}
    case " $keys " in *" $k "*) ;; *) echo "warning: $f:$n: unknown setting \"$k\" (settings are: $keys)" >&2; continue ;; esac
    if [ "$k" = serial ] || [ "$k" = include_uncommitted ]; then
      case "${v,,}" in
        true|yes|on) v=true ;; false|no|off) v=false ;;
        "") continue ;;
        *) echo "warning: $f:$n: $k must be true or false, not \"$v\"; ignored" >&2; continue ;;
      esac
    fi
    [ -z "$v" ] && [ "$k" != base ] && [ "$k" != models ] && continue
    val[$k]=$v; src[$k]=$f
  done < "$f"
done
for k in $keys; do printf '%s: %s | from %s\n' "$k" "${val[$k]:-(empty)}" "${src[$k]}"; done
