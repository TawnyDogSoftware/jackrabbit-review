---
name: jackrabbit-review
license: MIT
description: Jackrabbit review - a deep, multi-agent review of the current branch, meant to leave nothing for a later review round to find. Five independent reviewers with different focuses (state and async, data integrity, boundary, conformance, geometry and gestures), a merge that drops nothing, a check of every finding against the code, and one ranked list. Use only when the user asks for it by name, in any wording ("perform a jackrabbit review", "run jackrabbit on this branch", "jackrabbit this against develop", "/jackrabbit-review"). Do not use it for a review request that does not name it, however thorough the user wants it to be - it takes seven to nine agent runs and 20 to 30 minutes or more; offer it instead. With "help" it only explains how to use it.
argument-hint: "[help] [what to review against, which models, run one at a time, include uncommitted changes - all in your own words]"
---

# Jackrabbit review

Review the change on the current branch with five focused reviewers, then merge and verify.

You are the orchestrator. You do not review the code yourself, and you do not edit, shorten or
re-judge what the reviewers write. Your job is to start each stage with the right prompt file,
check that its output exists, and assemble the final list.

## How you were started

What was passed to this skill, if anything: `$ARGUMENTS`

- **By the slash command:** that text is what the user typed after it.
- **On your own,** because the user asked for a jackrabbit review by name: their request is
  that text. Before step 1, tell the user in one line that you are running a jackrabbit review
  and that it takes seven to nine agent runs. Do not wait for an answer.

Only start this skill on your own when the user named it. If they asked for a careful or
thorough review without naming it, do an ordinary review and mention that a jackrabbit review
exists and what it costs; do not start one.

Either way this skill needs a tool that starts agents. If you have none (you are yourself a
subagent that may not start others, for instance), say so and stop. Do not do the five reviews
yourself in one pass and call it a jackrabbit review: it is not one.

## Where this skill is

`<skill dir>` below is the directory that holds this `SKILL.md`. Your harness normally says
which directory that is when it loads the skill. If it did not, find it:

    for d in .claude/skills .agents/skills ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills; do [ -f "$d/jackrabbit-review/SKILL.md" ] && { cd "$d/jackrabbit-review" && pwd -P; break; }; done

Use the absolute path it prints. The helper scripts are in `<skill dir>/scripts/`.

## Help

If the arguments are `help`, `--help` or `-h`, or the user asks how to use this skill, what it
does or what its options are, and is not asking for a review, your whole task is:

1. Run `cat <skill dir>/help.md`.
2. Reply with that output and nothing else: every line, unchanged, starting with its first line
   `# Jackrabbit review`. The help is that file. This file is instructions for you, not help
   for the user, and a summary of it in your own words is not what was asked for.
3. Stop. Do not run `prepare.sh` and do not start any agent.

## Settings

There are no flags. The user says what they want in words, and settings files give the defaults.

**1. Read the settings files.** From the repository being reviewed, run:

    <skill dir>/scripts/settings.sh

It prints one line per setting with its value and the file it came from: the defaults shipped
in `<skill dir>/jackrabbit-review-config.yaml`, then the user's
`~/.config/jackrabbit-review-config.yaml`, then `jackrabbit-review-config.yaml` in the
repository's root, each overriding the one before. Show any warning it
prints to the user and carry on.

**2. Apply what the user said.** Anything in the request overrides the files for this run:

| Setting | Values | The user says, for example |
|---|---|---|
| `base` | the branch or commit to measure against; empty means the pull request's base branch when `make_pr_comments` is `true`, otherwise the remote's default branch | "against develop", "compare with main", "since abc123" |
| `serial` | `true`: one agent at a time; `false`: side by side | "run the agents in serial", "one at a time", "go easy on the rate limit"; "run them all at once" |
| `include_uncommitted` | `true`: also review uncommitted changes | "also review my uncommitted code", "include what I haven't committed"; "only what's committed" |
| `make_pr_comments` | `true`: post the findings to the branch's pull request as inline comments with suggested fixes (step 6); `false`: report them here only | "make inline comments on the PR for findings", "comment on the PR with whatever jackrabbit finds", "post it to the PR"; "don't comment on the PR", "just tell me" |
| `models` | words naming models, as in "Choosing the models" | "use fable", "opus on high to verify" |

Act only on a plain instruction. A sentence that mentions one of these in passing, or a branch
name that happens to contain a word, is not one. If something the user asked for is not one of
these settings (to skip the verification, for instance), say that it is not an option of this
review and carry on without it: verifying every finding is the point of this review.

**3. When `make_pr_comments` is `true`, check the pull request,** before any agent starts:

    <skill dir>/scripts/pr-check.sh

It needs the GitHub CLI (`gh`, signed in) and `jq`, and prints the pull request's URL, its base
branch and its head. If it ends with `ok` and `base` is empty, use `origin/<pr_base>` as the base. If it prints a
`problem:` line (no `gh`, not signed in, no open pull request for this branch, or the pull
request's head is not this `HEAD` because the branch has not been pushed), the review still
runs; the problem goes in the settings line below. Do not push or create a pull request to fix
it yourself.

**4. Say what applies, before you run anything else.** Tell the user in one line the settings that are not the
defaults and where each came from, for example: "Settings: against develop (you); one agent at
a time (~/.config/jackrabbit-review-config.yaml); uncommitted changes included (you)." If all
are defaults, say "default settings". When `make_pr_comments` is `true`, end the line with
"comments go to <pull request URL>", or with the problem `pr-check.sh` printed and "findings
will be reported here only unless that is fixed before the review ends". Do not run
`prepare.sh` before this line has been shown. Do not wait for an answer.

The review covers everything from the merge base with `base` to `HEAD`, plus uncommitted
changes when `include_uncommitted` is `true`.

## Choosing the models

Skip this section when neither the user nor the `models` setting says which models to use:
every stage then runs on the default. Otherwise do this before step 1. What the user said
replaces the setting entirely; it is not merged with it.

1. **Read what was asked, stage by stage.** The stages are the five reviewers (`state`, `data`,
   `boundary`, `conformance`, `geometry`), the merge and the verifiers. A model named without a
   stage is for all of them. "The reviewers" is all five; "verify", "the check" or "the
   verifiers" is the verify stage. Words such as "on high", "max effort" or "low thinking" are
   the effort level, which opencode calls the variant. Act only on a plain instruction: a branch
   called `opus-fix`, or a sentence that mentions a model in passing, is not one.
2. **Find what each model is called where you are running.** Do not write a name from memory.
   - Claude Code: the models are the values the Agent tool's `model` parameter lists, and the
     efforts the values its `effort` parameter lists. Those names are families (`opus`), not
     versions. If the user named a version ("opus 5.5"), use the family, and say that the tool
     picks the version. If you have reason to think the family is now a different version than
     the one asked for, say so and ask before starting.
   - opencode: look the id up with the models tool or `opencode models`. It has the form
     `<provider>/<model>`.
   - A model the tool you start agents with cannot reach (another provider's, for instance):
     if your harness has a different tool that starts an agent on that model, you may use it,
     with the same one-line prompt and the reviewed repository as its working directory.
     Otherwise it cannot be started from here.
3. **Settle anything unclear before an agent starts.**
   - More than one name fits: prefer the one that adds nothing to what was said (the plain
     model over a fast or flex edition of it); between versions take the newest unless a
     version was named. If more than one still fits, ask the user, listing them.
   - None fits, or it cannot be started from here: say what was asked for and what is
     available, and stop.
   - Never run a stage on a different model than the one asked for, and never fall back to the
     default without saying so. A review costs seven to nine agent runs; a question costs none.
4. **Write the result down and say it.** Put it into one value for `prepare.sh --model`: a
   comma-separated list without spaces, of `<model>` (every stage) and `<stage>=<model>` items
   (`reviewers` for all five, or a stage name), where later items override earlier ones and a
   model can end in `#<effort>`. For example `fable,verify=opus#high`, or in opencode
   `reviewers=openai/gpt-6-sol#high`. Put the value in single quotes on the command line. A
   stage you leave out keeps the default. Then tell the user in one line what you settled on
   for every stage, with the names as you will pass them (for `fable,verify=opus#high`:
   "Models: reviewers and merge `fable`, medium; verify `opus`, high"; a stage left on the
   default is listed as the default), and carry on without waiting unless step 3 told you to
   ask.

The prompts were tuned and scored on the default in Claude Code. They run on other models, but
how well another model reviews with them has barely been measured.

## Starting an agent

Every stage below starts agents the same way. Which tool that is depends on where you run, and
the model comes from the end of the stage's line (`| model <model>`) that the scripts print:

- **Claude Code:** the Agent tool with `subagent_type: general-purpose` and
  `run_in_background: false`.
  - `model default`: `model: opus`, `effort: medium`. This is the configuration the prompts were
    tested with.
  - `model <name>` or `model <name>#<effort>`: `model: <name>`, and `effort: <effort>`, or
    `effort: medium` when none was written. `<name>` must be a model the Agent tool offers.
- **opencode:** the tool that starts a subagent (`subagent`; `task` in older versions), with the
  agent `jackrabbit-reviewer`. That agent may not use the network, GitHub, skills or further
  agents. If it is not in the tool's list of agents, it is not installed: use the agent
  `general` instead, and tell the user once, before the first agent starts, that the reviewers
  run without those limits until they install it with
  `mkdir -p ~/.config/opencode/agent && cp <skill dir>/opencode/jackrabbit-reviewer.md ~/.config/opencode/agent/`.
  - `model default`: do not pass a model. The agent's own model is used: the one in its file
    (`~/.config/opencode/agent/jackrabbit-reviewer.md`) if that sets one, otherwise the model of
    this session.
  - `model <provider>/<model>` or `model <provider>/<model>#<variant>`: pass exactly that text
    as the tool's `model`. If the tool has no `model` parameter, this version of opencode
    cannot choose a model per agent: say so and stop.
  - Where the tool returns at once with a session id, a stage is finished when its
    `<subagent>` message arrives. Wait for that before you check the output file, and when
    `serial` is `true` before you start the next agent.

In both, the prompt for an agent is exactly this and nothing more:

    Your complete task is written in the file <prompt file>. Read that file and carry it out exactly.

Do not add a description of the change, your own concerns, or anything another agent said.

## 1. Prepare

From the repository being reviewed, run:

    <skill dir>/scripts/prepare.sh [<base>] [--include-uncommitted] [--model '<value>']

with `<base>` when the `base` setting is not empty, `--include-uncommitted` when
`include_uncommitted` is `true`, and `--model` with the value from "Choosing the models" when
models were named. These are the script's own options; the user never types them.

It resolves the base, creates a run directory inside the git directory (nothing is added to the
working tree), renders the prompts, and prints the run directory, the diff size, the models that
were named, and one line per reviewer with its prompt file, report file and model. Check that
the models on those lines are the ones you told the user. If it exits with an error, show the
user the message and stop; if the error is about the `--model` value you wrote, correct the
value and run it again.

## 2. Five reviewers

Start one agent per reviewer line that `prepare.sh` printed, on that line's model: state, data, boundary, conformance, geometry. The geometry reviewer ends early by itself when the change has no gesture, layout or chooser code.

- Send all five in one message so they run side by side. When `serial` is `true`, send them one
  at a time and wait for each.
- Each reviewer must come to the code without a hint: the one-line prompt above, with that
  reviewer's prompt file, is all it gets.

When they return, check that each report file exists and is not empty. If an agent failed (a rate
limit, a timeout, no file), start that one again by itself, once. If it fails again, continue
without it and say in the final summary which reviewer is missing: every reviewer finds things
the others do not, so a missing one means a weaker review.

## 3. Merge

Start one agent the same way, pointing at the merge prompt file, on the model at the end of the `merge:` line. It writes `merged.md` in the run directory. It reads only the five reports.

Check that `merged.md` exists.

## 4. Verify

Run:

    <skill dir>/scripts/verify-batches.sh <run directory>

It prints the number of findings and one line per verifier with its prompt file, output file
and model (one verifier per 14 findings or fewer). Start one agent per line, the same way; in
one message, or one at a time when `serial` is `true`.

Each verifier tries to refute its findings against the code and writes a table with one verdict
per finding: REAL, REAL-MINOR, UNVERIFIED, LATENT, INTENDED or WRONG. It also checks each
finding's Reach line (what triggers it today) against the code: a Reach line is a
claim and can be wrong, so it is never used unchecked.

## 5. Assemble and report

Read every `verdicts-*.md` in full. From `merged.md` read only the finding headings and sections
2 to 4 (leads not investigated, design questions, pre-existing defects). Do not load the full
merged review into your context; point to it.

Write `summary.md` in the run directory and give the same content to the user:

1. **Fix.** Findings rated REAL, by severity: id, title, the deciding `file:line`, and one
   sentence on what goes wrong.
2. **Decide.** UNVERIFIED and LATENT findings: what was confirmed, and what would settle it or
   what would have to exist for it to be reached. Take reach from the verifier's column, not
   from the reviewers' Reach lines; where the verifier marked a Reach line as wrong, say so.
3. **Minor.** REAL-MINOR findings, one line each.
4. **Set aside.** INTENDED and WRONG findings, one line each, with the document or line that
   defeats them. They are listed, never deleted: a verifier can be wrong.
5. **Leads not investigated**, design questions and pre-existing defects, as the merge listed them.
6. **Run.** Base and head, diff size, the settings that were not defaults, which reviewers ran, the model each stage ran on (the
   actual model, also where the line said `default`; where a stage ran on anything but Opus on
   medium effort in Claude Code, add that the prompts were tuned on that configuration, not on
   this one), anything that failed or was skipped, and the paths to `merged.md` (full scenarios
   and fix constraints for every finding) and the verdict files.

Use the verifiers' verdicts as written. If you believe one is wrong, say so in a separate note
under the list; do not move the finding.

## 6. Comment on the pull request

Only when `make_pr_comments` is `true`. Otherwise the review ends with step 5.

1. Run `<skill dir>/scripts/pr-check.sh <run directory>` again: it checks that the pull request's
   head is still the reviewed commit and writes `pr.json`. If it prints a `problem:` line, do
   not post. Tell the user why, and that the findings are in `summary.md`.
2. Write `<run directory>/pr-comments.json`:

       {"summary": "<markdown>", "comments": [{"finding": "F3", "path": "src/a.ts", "line": 42, "start_line": 40, "body": "<markdown>"}]}

   - One comment per finding rated REAL or REAL-MINOR, on its deciding line: the `file:line`
     from the verdict table, as a path from the repository root and a line number in the file
     at `HEAD`. Add `start_line` only when the finding is about a range of lines that ends at
     `line`. For these findings, read their sections in `merged.md`.
   - Each comment body: a first line `**jackrabbit-review <id> · <verdict> · <severity>:**
     <title>`; then what goes wrong, in two to four sentences with the concrete scenario from
     the merged review; then `**Suggested fix:**` and the fix constraint from the merged review
     in words, including what the fix must not break. Do not write a ```suggestion block or
     code: no agent has checked a fix against the code.
   - `summary`: one line saying this is an automated jackrabbit review, the counts by verdict,
     the models it ran on, and then the Decide list (UNVERIFIED and LATENT findings, one line
     each with `file:line`). Do not post INTENDED or WRONG findings or the leads.
3. Run `<skill dir>/scripts/post-review.sh <run directory>`. It posts everything as one review
   (comment only, never an approval or a request for changes). A comment whose line is not in
   the pull request's diff goes into the review's summary instead, with its `file:line`. It
   prints the review's URL.
4. Add to the Run section of `summary.md`, and tell the user: the URL, how many comments were
   inline and how many went into the summary. If posting failed, give the error and say the
   findings are in `summary.md`; do not retry more than once.

Post once per run. If the user asks to post again later, use the same run directory.

## Rules

- Read-only. Do not fix anything, commit or push as part of this skill. If the user wants fixes,
  that is a separate request after they have seen the list.
- The only thing this skill writes outside the run directory is the pull request review of
  step 6, and only when `make_pr_comments` is `true`.
- No reviewer, merge or verify agent may use GitHub or read earlier review comments. The value
  of the review is that it comes from the code alone. Only you use `gh`, and only through
  `pr-check.sh` and `post-review.sh`.
- Report what happened. If a stage failed or a reviewer is missing, the summary says so first.
- Do not change the prompt files as part of a review. If a later review or a bug shows a defect
  this review missed, the prompts are changed separately and tested against earlier cases first
  (the maintainers use the `update-jackrabbit-review` skill for that).
