#!/bin/bash
# Post a jackrabbit review's findings to its pull request as one GitHub review with inline comments.
# usage: post-review.sh <run-dir> [--dry-run]
# Reads <run-dir>/pr.json (from pr-check.sh) and <run-dir>/pr-comments.json, written by the
# orchestrator:
#   {"summary": "<markdown for the review's top comment>",
#    "comments": [{"finding": "F3", "path": "src/a.ts", "line": 42, "start_line": 40, "body": "<markdown>"}]}
# "start_line" is optional (a range ending at "line"). Paths are relative to the repository root;
# lines are line numbers in the file at the pull request's head.
# GitHub accepts an inline comment only on a line that the pull request's diff shows. A comment
# whose lines are not in the diff is not dropped: it is added to the summary with its path and
# line. Posts nothing if the pull request's head has moved since pr-check.sh ran.
# With --dry-run, writes <run-dir>/pr-review-payload.json and prints what would be posted.
# Otherwise prints the review's URL and writes it to <run-dir>/pr-review.txt.
set -euo pipefail
run=${1:?usage: post-review.sh <run-dir> [--dry-run]}; dry=${2:-}
for f in pr.json pr-comments.json; do [ -s "$run/$f" ] || { echo "missing $run/$f" >&2; exit 2; }; done
jq -e '.summary and (.comments | type == "array")' "$run/pr-comments.json" >/dev/null \
  || { echo "$run/pr-comments.json needs \"summary\" and a \"comments\" array" >&2; exit 2; }
repo=$(jq -r .repo "$run/pr.json"); n=$(jq -r .number "$run/pr.json"); head=$(jq -r .head "$run/pr.json")

now=$(gh api "repos/$repo/pulls/$n" --jq .head.sha)
[ "$now" = "$head" ] || { echo "the pull request's head moved from $head to $now since the review; not posting" >&2; exit 3; }

# Right-hand line numbers the diff shows, per file: {"path": [lines...]}
lines=$(gh api --paginate "repos/$repo/pulls/$n/files?per_page=100" | jq -s '
  [ .[][] | select(.patch != null) | {key: .filename, value: (
      .patch | split("\n") | reduce .[] as $l ({n: 0, out: []};
        if ($l | startswith("@@")) then .n = ($l | capture("\\+(?<s>[0-9]+)").s | tonumber)
        elif ($l | startswith("-")) or ($l | startswith("\\")) then .
        else .out += [.n] | .n += 1 end) | .out)} ] | from_entries')

payload=$(jq -n --slurpfile c "$run/pr-comments.json" --argjson lines "$lines" --arg head "$head" '
  $c[0] as $in
  | def shown($p; $l): ($lines[$p] // []) | any(.[]; . == $l);
    def ok: shown(.path; .line) and ((.start_line // .line) as $s | shown(.path; $s) and $s <= .line);
  ($in.comments | map(select(ok))) as $inline
  | ($in.comments | map(select(ok | not))) as $outside
  | {commit_id: $head, event: "COMMENT",
     body: ($in.summary
       + (if ($outside | length) > 0 then
           "\n\n### Findings outside this pull request'"'"'s diff\n\n"
           + ($outside | map("**" + (.finding // "") + "** `" + .path + ":" + (.line | tostring) + "`\n\n" + .body) | join("\n\n---\n\n"))
         else "" end)
       + "\n\n<!-- jackrabbit-review -->"),
     comments: ($inline | map({path, line, side: "RIGHT", body}
       + (if (.start_line // .line) < .line then {start_line, start_side: "RIGHT"} else {} end)))}')

inline=$(jq '.comments | length' <<<"$payload"); total=$(jq '.comments | length' "$run/pr-comments.json")
echo "inline comments: $inline; in the summary because their lines are not in the diff: $((total - inline))"
if [ "$dry" = --dry-run ]; then
  printf '%s\n' "$payload" > "$run/pr-review-payload.json"
  echo "dry run: payload written to $run/pr-review-payload.json"; exit 0
fi
url=$(gh api -X POST "repos/$repo/pulls/$n/reviews" --input - --jq .html_url <<<"$payload")
printf '%s\n' "$url" > "$run/pr-review.txt"
echo "posted: $url"
