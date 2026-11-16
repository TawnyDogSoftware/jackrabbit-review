# Jackrabbit review

A deep review of the change on the current branch, meant to leave nothing for a later review
round to find. Five reviewers each look for a different kind of defect (state and async, data
integrity, boundary, conformance, geometry and gestures). Their reports are merged without
dropping anything, every finding is checked against the code, and you get one ranked list.

It only reads. It does not fix, commit, push or comment on a pull request.

## Run it

From the repository, on the branch to review:

    /jackrabbit-review
    /jackrabbit-review against develop
    /jackrabbit-review help            show this

Or ask by name: "perform a jackrabbit review", "do a jackrabbit review against develop". It
only starts when you name it; a request for a careful review that does not say "jackrabbit"
gets an ordinary review.

## Options

There are no flags. Say what you want, in the same message:

| You say | What it does |
|---|---|
| "against develop", "compare with main" | Measures the change against that branch or commit. Default: the remote's default branch. Everything from the merge base to `HEAD` is reviewed. |
| "run the agents in serial", "one at a time" | One agent at a time. Slower, but easier on rate limits and usage. |
| "also review my uncommitted code" | Includes staged, unstaged and new files. Without it, uncommitted changes stop the run. |
| "use fable", "fable for the reviewers and opus on high to verify" | Chooses the models. See below. |

Every finding is always checked against the code; that cannot be turned off.

## Settings files

To make one of these the default, put it in a settings file. Same keys in each; the later file
wins, and what you say when you start a review wins over all of them:

1. `jackrabbit-review-config.yaml` in this skill's directory: the defaults. A reinstall or
   update replaces it.
2. `~/.config/jackrabbit-review-config.yaml`: yours, for every repository.
3. `jackrabbit-review-config.yaml` in a repository's root: for that repository.

For example:

    serial: true                 # always one agent at a time
    include_uncommitted: true    # always include uncommitted changes
    base: develop                # measure against develop
    models: fable for the reviewers and opus on high to verify

The review says at the start which settings apply and where each came from.

## Choosing the models

You are told in one line what was settled on before any agent starts. If a model cannot be
started from where you are, the run stops; it never substitutes another model.

Without a choice, every agent runs on the default: Opus on medium effort in Claude Code, and in
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
