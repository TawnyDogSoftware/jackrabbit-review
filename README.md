# jackrabbit-review

An agent skill for a deep review of the change on your current branch, meant to leave nothing
for a later review round to find.

Five reviewers work independently, each looking for one kind of defect:

| Reviewer | Looks for |
|---|---|
| state | Client state, async flows and their interleavings, timing, derived state, notifications, retries |
| data | Writes, concurrency, locks, stored records, transforms, queries and ordering, limits, completeness |
| boundary | Permissions, error handling and mapping, hostile or unusual input, connections and resources |
| conformance | Regressions against the base, repository rules, documents against the code, tests, wiring |
| geometry | Measurement, hit tests, choosers among candidates, gestures, scrolling, animation |

A merge step combines their reports without dropping anything. Verifiers then try to refute
every finding against the code, and you get one ranked list: fix, decide, minor, set aside.

It only reads. It does not fix, commit, push or comment on a pull request, and no reviewer may
use GitHub or read earlier review comments: the review comes from the code alone.

## Install

    npx skills add <owner>/<repo> --skill jackrabbit-review

Works with Claude Code and opencode, and with other agents that load skills and can start
subagents.

**opencode:** also install the reviewer agent once, so the reviewers cannot use the network,
GitHub, skills or further agents:

    mkdir -p ~/.config/opencode/agent
    cp ~/.agents/skills/jackrabbit-review/opencode/jackrabbit-reviewer.md ~/.config/opencode/agent/

(Use the path the installer printed if it differs.) Add `model:` and `variant:` lines to that
file to choose the reviewers' default model; without them they use the session's model.

## Use

From the repository, on the branch to review, with your work committed:

    /jackrabbit-review                 review HEAD against the default branch
    /jackrabbit-review develop         measure against another branch or commit
    /jackrabbit-review help            how to use it

Or ask by name: "perform a jackrabbit review against develop". The skill starts only when it is
named; a request for a careful review that does not say "jackrabbit" gets an ordinary review.

Options: `--serial` (one agent at a time), `--no-verify` (stop after the merge),
`--include-uncommitted` (also review uncommitted changes).

**Models.** Say it in words: "use fable", "fable for the reviewers and opus on high to verify",
"run the data reviewer on gpt-6 sol". The agent works out what that means where it runs, tells
you in one line before it starts, and stops instead of substituting if a model is not available.

## Cost

Seven to nine agent runs: five reviewers, one merge, and one verifier per 14 findings. The five
reviewers take 20 to 30 minutes one after another, less side by side. Use it before opening a
pull request on a change that matters, not on every commit.

## Output

Everything is kept in the reviewed repository's git directory, under
`.git/jackrabbit-review/<head>-<time>/`: `summary.md` (the ranked list), `merged.md` (the
scenario and fix constraint for every finding), the five reviewer reports and the verdicts.
Nothing is added to the working tree.

## How well it works

The reviewer prompts were developed and scored on 15 real changes from four repositories,
against the defects that later review rounds (review bots and people) found on them. On the
changes the prompts were not tuned on, the current set found every one of the expected defects
(7 of 7). That is a small sample. The scores are for Claude Opus on medium effort in Claude
Code; other models have barely been measured.

Run-to-run variation is real: a defect that only one reviewer is positioned to see is sometimes
missed on one run and found on the next.

Requires `git` and `bash`.
