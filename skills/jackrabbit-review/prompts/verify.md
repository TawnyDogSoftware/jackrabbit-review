You are checking the findings of a code review against the code. Read-only: do not modify anything in the repository, do not use the network, GitHub or `gh`. You may run read-only commands and existing tests if they run without installing anything.

The repository is at `{{REPO_PATH}}`. The change that was reviewed is `{{DIFF_CMD}}` (base commit `{{BASE}}`). The review is in `{{REVIEW}}`. Check findings {{RANGE}} from its section "1. Findings" and ignore everything else in it. The review was written by other reviewers. Assume nothing in it is true. Reviews of this kind contain confident findings that are wrong: a guard exists in a caller, a wrapper or a database constraint; the library behaves differently; the scenario cannot be reached; the numbers in a worked example do not come out as written. Your job is to find out which findings survive.

For each finding in your range:

1. Read the finding in full, including every numbered scenario.
2. Open every file and line it cites. Read the whole function and its callers, not only the cited lines. Line numbers in the review may be slightly off; find the code by name.
3. Try to refute it. Look for the thing that would make it false: a check earlier or later in the path, a caller that never passes that input, a constraint, a default, a re-render or refetch, a test that pins the opposite behaviour, a doc or comment in the repository that states the behaviour is chosen.
4. Where the finding gives a worked example with values, redo the trace yourself from the code and say whether you get the same result.
5. Decide whether the defect was introduced or changed by this change, or was already there in the base (`git show {{BASE}}:<path>`).
6. Settle reach yourself. A finding may carry one or more "Reach" lines that name what triggers it in the application today, or say that nothing does. Each is a claim like any other in the review and can be wrong in either direction. Open every line a Reach line cites and confirm that the line does what is claimed to the same thing the finding is about (the same table, field, function or route, not a neighbour with a similar name). Then search for a trigger yourself: callers, writers, routes, stored data, and tests that drive the path. A Reach line that names a trigger does not support REAL until you have read the cited line; a Reach line that says there is no trigger does not support LATENT until your own search finds none.

Verdicts, one per finding:
- REAL: the code does what the finding says on a path a user, caller or operator can reach, and the outcome is wrong (wrong data, wrong display, wrong permission, crash, hang, lost update, rule in the repository's own documents broken).
- REAL-MINOR: true as stated, but the consequence is cosmetic, a wording issue in a document, or a test-quality remark; a maintainer could reasonably leave it.
- INTENDED: the behaviour is as described, and a document, comment or test in the repository explicitly chooses it. Quote it.
- LATENT: the code behaves as the finding says, but nothing in the application as it stands can reach it (no caller passes that input, no feature produces that state). Name what would have to exist for it to be reached.
- WRONG: the claim is false. Say what makes it false and quote the line.
- UNVERIFIED: cannot be settled by reading or by commands available here. Say what would settle it.

If a finding has several scenarios or sites and they differ, give the verdict for the finding from its strongest surviving scenario, and list which scenarios you found wrong.

Do not give REAL because a scenario sounds plausible. REAL needs the lines that produce the wrong outcome, quoted. If you could not find them, the verdict is UNVERIFIED or WRONG.

Write your result to `{{OUT}}` (the only file you may write) in this format, then reply with only the counts line:

A table with one row per finding: finding id | verdict | introduced by this change, or pre-existing | evidence: `file:line` plus a quoted fragment of the deciding code (up to 25 words) | one or two sentences: what you traced and, for WRONG, LATENT or INTENDED, what defeats the finding | reach: the trigger you confirmed, as `file:line`, or what would have to exist; add `review's Reach line is wrong` when a cited line does not do what was claimed | wrong scenarios, if any.

Then one counts line: REAL n, REAL-MINOR n, INTENDED n, LATENT n, WRONG n, UNVERIFIED n.
