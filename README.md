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

## Use

From the repository, on the branch to review:

    /jackrabbit-review
    /jackrabbit-review against develop
    /jackrabbit-review help

Or ask by name: "perform a jackrabbit review against develop". The skill starts only when it is
named; a request for a careful review that does not say "jackrabbit" gets an ordinary review.

There are no flags. Say what you want:

- **Base:** "against develop", "compare with main". Default: the remote's default branch.
- **One agent at a time:** "run the agents in serial". Slower, easier on rate limits.
- **Uncommitted changes:** "also review my uncommitted code". Otherwise uncommitted changes stop
  the run.
- **Models:** "use fable", "fable for the reviewers and opus on high to verify", "run the data
  reviewer on gpt-6 sol". The agent works out what that means where it runs, tells you in one
  line before it starts, and stops instead of substituting if a model is not available.

## Settings

To make any of these the default, write it in a settings file. The later file wins, and what
you say when you start a review wins over all of them:

1. `config.yaml` in the skill's directory: the shipped defaults. An update replaces it.
2. `~/.config/jackrabbit-review/config.yaml`: yours, for every repository.
3. `.jackrabbit-review.yaml` in a repository's root: for that repository.

For example:

    serial: true                 # always one agent at a time
    include_uncommitted: true    # always include uncommitted changes
    base: develop                # measure against develop
    models: fable for the reviewers and opus on high to verify

The review says at the start which settings apply and where each came from.

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
Code.

## FAQ

### Is it good?

Yes.

### What does it cost?

Seven to nine agent runs: five reviewers, one merge, and one verifier per 14 findings. The five
reviewers take 20 to 30 minutes one after another, less side by side. Use it before opening a
pull request on a change that matters, not on every commit.

### How do I install it?

    npx skills add TawnyDogSoftware/jackrabbit-review

It works with Claude Code and opencode, and with other agents that load skills and can start
subagents. It needs `git` and `bash`.

### How do I set it up for opencode?

Also install the reviewer agent once, so the reviewers cannot use the network, GitHub, skills
or further agents:

    mkdir -p ~/.config/opencode/agent
    cp ~/.agents/skills/jackrabbit-review/opencode/jackrabbit-reviewer.md ~/.config/opencode/agent/

Use the path the installer printed if it differs. Add `model:` and `variant:` lines to that file
to choose the reviewers' default model; without them they use the session's model. Without the
agent the review still runs, on opencode's general agent, and says so.

### How do I update it?

    npx skills update jackrabbit-review

This replaces the skill's own `config.yaml`; settings in `~/.config/jackrabbit-review/` and in
your repositories are kept.

## License

MIT. See `LICENSE`.
