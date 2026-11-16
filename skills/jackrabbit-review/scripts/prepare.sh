#!/bin/bash
# Prepare a jackrabbit-review run for the repository in the current directory.
# usage: prepare.sh [<base-ref>] [--include-uncommitted] [--model <models>]
# Resolves the base commit, creates a run directory inside the git directory, renders the five
# reviewer prompts and the merge prompt, and prints the paths the orchestrator needs.
#
# --model says which model each agent runs on. <models> is a comma-separated list of
#   <model>            every reviewer, the merge and the verifiers
#   <stage>=<model>    one stage: reviewers (all five), state, data, boundary, conformance,
#                      geometry, merge, verify, or score (the scorer of update-jackrabbit-review)
# Later items override earlier ones, so "fable,verify=opus" runs everything on fable except the
# verifiers. A model may end in #<effort> (Claude Code) or #<variant> (opencode), as in opus#high
# or openai/gpt-6-sol#high. A stage that is not named runs on the default, which is whatever the
# skill starts agents with when no model is given. The script does not know which models exist;
# it records the choice in <run-dir>/models and prints it on each stage's line.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
lenses="state data boundary conformance geometry"
base_ref="" dirty_ok=0 model_spec=""
while [ $# -gt 0 ]; do
  case "$1" in
    --include-uncommitted) dirty_ok=1 ;;
    --model=*|--models=*) model_spec+="${model_spec:+,}${1#*=}" ;;
    --model|--models)
      [ $# -ge 2 ] || { echo "$1 needs a value, for example: --model fable,verify=opus" >&2; exit 2; }
      model_spec+="${model_spec:+,}$2"; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) base_ref=$1 ;;
  esac
  shift
done

declare -A model
for s in $lenses merge verify score; do model[$s]=default; done
IFS=',' read -ra items <<< "$model_spec"
for item in ${items[@]+"${items[@]}"}; do
  item=${item//[[:space:]]/}
  [ -n "$item" ] || continue
  if [[ $item == *=* ]]; then stage=${item%%=*}; m=${item#*=}; else stage=all; m=$item; fi
  if [ -z "$m" ] || [[ $m == *=* ]] || [[ $m == \#* ]] || [[ $m == *\# ]]; then
    echo "--model: cannot read \"$item\"; write <model> or <stage>=<model>, with an optional #<effort> after the model" >&2; exit 2
  fi
  case "$stage" in
    all) for s in $lenses merge verify; do model[$s]=$m; done ;;
    reviewers|reviewer|review) for s in $lenses; do model[$s]=$m; done ;;
    state|data|boundary|conformance|geometry|merge|verify|score) model[$stage]=$m ;;
    *) echo "--model: unknown stage \"$stage\" in \"$item\"; stages are reviewers, state, data, boundary, conformance, geometry, merge, verify, score" >&2; exit 2 ;;
  esac
done

repo=$(git rev-parse --show-toplevel)
cd "$repo"
head=$(git rev-parse HEAD)

if [ -z "$base_ref" ]; then
  base_ref=$(git symbolic-ref -q --short refs/remotes/origin/HEAD || true)
  if [ -z "$base_ref" ]; then
    for c in origin/main origin/master main master; do
      if git rev-parse -q --verify "$c^{commit}" >/dev/null; then base_ref=$c; break; fi
    done
  fi
  [ -n "$base_ref" ] || { echo "cannot find a default branch; pass the base ref" >&2; exit 2; }
fi
base=$(git merge-base "$base_ref" HEAD)

# Left out throughout, when untracked: .opencode/goals/ (session state an opencode plugin writes
# into whatever directory it runs from) and .jackrabbit-review.yaml (this skill's own settings).
# Neither is part of the change.
harness='^(\.opencode/goals/|\.jackrabbit-review\.yaml$)'
dirty=$(git status --porcelain --untracked-files=all | grep -Ev "^\?\? ${harness#^}" || true)
untracked_note=""
if [ -n "$dirty" ] && [ "$dirty_ok" = 0 ]; then
  echo "the working tree has uncommitted changes. Commit or stash them, or ask for them to be reviewed too (include_uncommitted in the settings, or say so when starting the review)." >&2
  exit 3
fi
if [ -n "$dirty" ]; then
  diff_cmd="git diff $base"
  untracked=$(git ls-files --others --exclude-standard | grep -Ev "$harness" || true)
  if [ -n "$untracked" ]; then
    untracked_note=" These new files are not tracked yet and do not appear in that diff; they are part of the change, so read them in full: $(echo "$untracked" | tr '\n' ' ')"
  fi
else
  diff_cmd="git diff $base $head"
fi
if [ "$base" = "$head" ] && [ -z "$dirty" ]; then
  echo "nothing to review: HEAD is the base ($base_ref)" >&2; exit 4
fi

runs="$(git rev-parse --absolute-git-dir)/jackrabbit-review"
mkdir -p "$runs"
run="$runs/$(git rev-parse --short HEAD)-$(date +%Y%m%d-%H%M%S)"
n=2; stem=$run
until mkdir "$run" 2>/dev/null; do run="$stem-$n"; n=$((n + 1)); [ "$n" -lt 50 ] || { echo "cannot create a run directory under $runs" >&2; exit 2; }; done

render() { # render <template> <output> <report-path>
  local text
  text=$(cat "$1")
  text=${text//'{{REPO_PATH}}'/$repo}
  text=${text//'{{DIFF_CMD}}'/$diff_cmd}
  text=${text//'{{BASE}}'/$base}
  text=${text//'{{UNTRACKED_NOTE}}'/$untracked_note}
  text=${text//'{{OUT}}'/$3}
  printf '%s\n' "$text" > "$2"
}

reports=""
for lens in $lenses; do
  render "$here/prompts/lens-$lens.md" "$run/prompt-$lens.md" "$run/report-$lens.md"
  reports+="- $run/report-$lens.md"$'\n'
done
text=$(cat "$here/prompts/merge.md")
text=${text//'{{REPORTS}}'/${reports%$'\n'}}
text=${text//'{{OUT}}'/$run/merged.md}
printf '%s\n' "$text" > "$run/prompt-merge.md"

printf '%s\n' "$repo" > "$run/repo"; printf '%s\n' "$base" > "$run/base"; printf '%s\n' "$diff_cmd" > "$run/diff_cmd"
for s in $lenses merge verify score; do printf '%s %s\n' "$s" "${model[$s]}"; done > "$run/models"
named=$(awk '$2 != "default" && !seen[$2]++ { printf "%s%s", (n++ ? ", " : ""), $2 }' "$run/models")

echo "run_dir: $run"
echo "base: $base ($base_ref)"
echo "head: $head"
echo "diff: $diff_cmd"
echo "size: $($diff_cmd --shortstat)"
echo "models named: ${named:-none (every stage runs on the default)}"
for lens in $lenses; do echo "reviewer $lens: prompt $run/prompt-$lens.md -> report $run/report-$lens.md | model ${model[$lens]}"; done
echo "merge: prompt $run/prompt-merge.md -> $run/merged.md | model ${model[merge]}"
