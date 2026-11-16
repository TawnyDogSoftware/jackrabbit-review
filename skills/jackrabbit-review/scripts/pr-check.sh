#!/bin/bash
# Check that review findings can be posted as comments on the pull request for the current
# branch, and print what the orchestrator needs. Run it from the repository under review.
# usage: pr-check.sh [<run-dir>]
# With <run-dir>, also writes <run-dir>/pr.json for post-review.sh.
# Prints "pr: <url>", "pr_base: <branch>", "pr_head: <sha>" and "head: <sha>", then either
# "ok" or one "problem: ..." line per thing that stops posting. Exit 0 when ok, 1 otherwise.
set -uo pipefail
problems=()
command -v gh >/dev/null || { echo "problem: the GitHub CLI (gh) is not installed: https://cli.github.com"; exit 1; }
command -v jq >/dev/null || { echo "problem: jq is not installed"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "problem: gh is not signed in; run: gh auth login"; exit 1; }
head=$(git rev-parse HEAD) || exit 1
if ! info=$(gh pr view --json number,url,state,headRefOid,baseRefName 2>&1); then
  echo "problem: no pull request found for the current branch ($(git branch --show-current)): ${info%%$'\n'*}"; exit 1
fi
url=$(jq -r .url <<<"$info"); state=$(jq -r .state <<<"$info")
pr_head=$(jq -r .headRefOid <<<"$info"); base=$(jq -r .baseRefName <<<"$info")
echo "pr: $url"; echo "pr_base: $base"; echo "pr_head: $pr_head"; echo "head: $head"
[ "$state" = OPEN ] || problems+=("the pull request is $state, not open")
[ "$pr_head" = "$head" ] || problems+=("the pull request's head ($pr_head) is not this branch's HEAD ($head); push the branch, or check out the pull request's head, so that the comments point at the code that was reviewed")
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "note: the working tree has uncommitted changes; findings in them cannot be commented on the pull request and will go in the review's summary"
fi
if [ ${#problems[@]} -gt 0 ]; then printf 'problem: %s\n' "${problems[@]}"; exit 1; fi
if [ -n "${1:-}" ]; then
  # https://github.com/<owner>/<repo>/pull/<n>
  repo=$(sed -E 's#^https://[^/]+/([^/]+/[^/]+)/pull/[0-9]+$#\1#' <<<"$url")
  jq -n --arg url "$url" --arg repo "$repo" --argjson number "$(jq .number <<<"$info")" --arg head "$pr_head" --arg base "$base" \
    '{url: $url, repo: $repo, number: $number, head: $head, base: $base}' > "$1/pr.json"
fi
echo ok
