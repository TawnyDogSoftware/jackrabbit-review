# Jackrabbit review

A deep review of the change on the current branch, meant to leave nothing for a later review
round to find. Five reviewers each look for a different kind of defect (state and async, data
integrity, boundary, conformance, geometry and gestures). Their reports are merged without
dropping anything, every finding is checked against the code, and you get one ranked list.

It only reads. It does not fix, commit, push or comment on a pull request.

## Run it

From the repository, on the branch to review, with your work committed:

    /jackrabbit-review                 review HEAD against the default branch
    /jackrabbit-review develop         measure against another branch or commit
    /jackrabbit-review help            show this

You can also just ask, by name: "perform a jackrabbit review", "do a jackrabbit review against
develop". It only starts when you name it; a request for a careful review that does not say
"jackrabbit" gets an ordinary review.

## Options

| Option | What it does |
|---|---|
| `<base-ref>` | The branch or commit the change is measured against. Default: the remote's default branch. Everything from the merge base to `HEAD` is reviewed. |
| `--serial` | One agent at a time. Slower, but easier on rate limits and usage. |
| `--no-verify` | Stop after the merge. You get the merged findings without the check against the code. |
| `--include-uncommitted` | Also review uncommitted changes. Without it, an unclean working tree stops the run. |

## Choosing the models

Say it in your own words, in the same message:

    /jackrabbit-review use fable
    /jackrabbit-review develop use fable for the reviewers and opus on high to verify
    /jackrabbit-review run the data reviewer on gpt-6 sol

You are told in one line what was settled on before any agent starts. If a model cannot be
started from where you are, the run stops; it never substitutes another model.

Without this, every agent runs on the default: Opus on medium effort in Claude Code, and in
opencode the model set in `~/.config/opencode/agent/jackrabbit-reviewer.md`, or the session's
model if that file sets none. The reviewer prompts were tuned on the Claude Code default.

In opencode, install the reviewer agent once, so that the reviewers cannot use the network,
GitHub, skills or other agents: copy `opencode/jackrabbit-reviewer.md` from this skill's
directory to `~/.config/opencode/agent/`. Without it the review still runs, on opencode's
general agent, and says so.

## What it costs

Seven to nine agent runs: five reviewers, one merge, and one verifier per 14 findings. The five
reviewers take 20 to 30 minutes one after another, less side by side.

## What you get

1. **Fix**: findings confirmed against the code, by severity.
2. **Decide**: findings that could not be confirmed, or that nothing triggers today.
3. **Minor**: real but small.
4. **Set aside**: findings the check rejected, with the line or document that defeats each one.
5. Leads that were not followed up, design questions, and defects that were already there.

Everything is kept in the repository's git directory, under `jackrabbit-review/<head>-<time>/`:
`summary.md` (the list above), `merged.md` (the full scenario and fix constraint for every
finding), the five `report-*.md` files and the `verdicts-*.md` files. Nothing is added to the
working tree.

## When it misses something

If a later review or a bug shows a defect this review did not report, the reviewer prompts can
be taught to find that kind of defect. With the `update-jackrabbit-review` skill installed, run
`/update-jackrabbit-review` with the defect; `/update-jackrabbit-review help` explains it.
Otherwise, report the miss to whoever maintains your copy of this skill.
