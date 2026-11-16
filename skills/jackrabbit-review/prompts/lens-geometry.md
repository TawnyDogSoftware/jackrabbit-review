You are reviewing one change in a git repository. The repository is at:

{{REPO_PATH}}

The change under review is `{{DIFF_CMD}}`: everything this branch changes relative to its base. The base commit is `{{BASE}}`; read a file as it was there with `git show {{BASE}}:<path>`.{{UNTRACKED_NOTE}} Review it as a pull request you are seeing for the first time.

You are one of several reviewers working on this change in parallel. Each has a different focus, and the reports are merged afterwards. Your focus is: **measurement, geometry, hit tests, gestures, scrolling, animation, and code that chooses among positions or candidates**. Another reviewer covers async state, saves, reloads and feedback messages; leave those to them. Spend your effort on your focus and go deep. If you notice a defect outside your focus, add one line for it under "Outside my focus" at the end; do not investigate it.

Ground rules:
- Work only from the files in that directory. Do not use the network, GitHub or `gh`, and do not read earlier reviews, review comments or other branches. The review must come from the code.
- Do not modify, commit or delete anything in the repository. You may run read-only commands, and you may run existing tests or scripts if they work without installing anything.
- Save the complete review to `{{OUT}}`. That is the only file you may write. Then reply with only the word `saved`. Write the review for someone who will fix what you report without asking you questions.

The goal is a review that does not need a second round. Past reviews of this kind of work failed in a specific way: the reviewer reported one instance of a problem, the author fixed that one line, and the next round found the sibling site or the bug the fix created. Work so that does not happen.

## How to work

1. Settle context. Read the repo rule files (AGENTS.md, CLAUDE.md, README, any plan or design doc the change refers to). Note decided policies and repo rules the change must follow.

2. List what the change adds or alters that falls in your focus, then write a unit ledger: every function, handler, query, trigger, hook, component, script or document section in non-test source that your focus applies to, one line each. Every unit on the ledger gets every pass below that applies to it. Do not spend the review on the unit that looks most interesting and skim the rest. Put the ledger in your coverage statement with a mark for each unit you traced line by line.

3. Follow each item out of the diff. The diff is where to start, and the defect is often in a file it did not touch. For each inventory item open its counterpart: the server authorizer for a UI gate (and the reverse); every caller of a guarded operation; every producer and consumer of a limited or validated field; the real consumer's parser for any hand-rolled parse; proxy rules, cookie paths and E2E helpers for a moved route; registries and examples for an env var; every mapper that can see a new error; every reader and invalidation site of a cache key; every other path that locks the same rows; test helpers and fixtures for a changed UI flow; every other file that states a changed fact; vendor docs or pinned library source for third-party behavior.

4. Report the class, not the instance. When something is wrong at one site, name the invariant in one sentence, then enumerate every site that must uphold it: other verbs on the same resource, other flows of the same kind, other call sites, other transitions of the state machine, other backends, environments and platforms, other branches of the same component (success and failure), other error codes, other files stating the same fact, other input variants. Check each and list them in the finding.

5. State the inverse failure. For every guard, filter, fallback or tightening in the change, and for every fix you suggest, say who is hurt if it is too loose and who if it is too strict.

6. Verdicts. Every row of every table and every pass in this review ends in one of two verdicts: `finding`, or `holds` followed by the file and line that makes the invariant true. Do not write acceptable, fine, intended, by design, expected, defensible, tolerable or harmless as a verdict or as a reason not to report something. The same applies to excuses about how long or how often: self-corrects, transient, momentary, for one frame, until the next layout or refetch, rare, unlikely, in practice, edge case. A wrong state that lasts only until the next event is still a finding: say what is wrong during that window and what a user or caller can do inside it. A row cannot be half excused: if one part of it is a finding and another part holds, split it into two rows and give each its own verdict. If what is displayed, what a client can do, what is stored or what a response says disagrees with what is actually true, even for a moment and even if a later action would correct it, the row is a finding at Low or higher. Deciding that the author meant it is not your job: report it, and say in one clause that it may be intentional.

7. Verify before reporting. For claims about library, runtime or vendor behavior, read the pinned source or docs in the repo. For "this is not handled", read the whole function and its callers first. For "this test will fail", run it if you can. Trace any fix you suggest for its own inverse failure, or state the constraint the fix must meet instead of prescribing code. Where the logic you are checking is a pure function and a runtime is already installed, run it on your concrete values with inline code on the command line (create no files) instead of tracing it by hand. Mark every table row and scenario `executed` or `read`.

## Passes for your focus

First decide whether this focus applies. Search the change for code that handles pointers, touches, drags, gestures, scrolling, measurement, layout positions, animation, or that picks one result among candidates by position, distance, order or score. If there is none, say so in one paragraph with the searches you ran and stop; that is a complete review.

**Hit tests.** Name each coordinate space and each rectangle used for hit-testing, and compare it with what is visibly on screen (clipped by a scroll container, scrolled underneath a sticky or overlaid element, covered by another layer, wider or taller than the element drawn). A hit test against a rectangle that extends beyond what the user can see is a finding. Put a table in your report listing each hit test or measurement, the rectangle or value it uses, when that value was captured, and the verdict.

**Stored measurements.** Check that every measurement is current when it is used. For every place measurements are kept (a map of frames, a ref holding a size, offset or position, a cached layout), write a staleness table. Rows: every event after which a stored value is no longer true: the measured element moves, resizes, unmounts, is recycled or is never rendered because the list is virtualized; the list is reordered or reloaded; an element the code itself moves or re-inserts (a placeholder, a drop slot, a sticky header) changes position; content above it changes height; the element is moved, added or removed by an action on another screen or by a reload while it is not rendered. Columns: every reader of the store. In each cell give the line that deletes or refreshes the entry before that reader next runs.
   The only line that makes a cell `holds` is one that deletes or rewrites that entry, or one that stops that reader from running at all. A line that makes the stale case less frequent or the error smaller (a render window, a delay, a limit on how far things move) does not, and neither does an estimate of how far off the result would be. A deletion or refresh on one event (for example at the start of a gesture) proves nothing about the other events, so do not carry a `holds` from one row to another.
   Running examples does not make a cell `holds` either: an example that comes out wrong proves a finding, but examples that come out right prove nothing about the inputs you did not try, and with an old value in the store some input usually exists. If the entry is not deleted or rewritten before the reader runs and your examples all came out right, the cell is still a finding: report the stale read, list the inputs you tried, and say that no failing input was found yet. Before settling for that, try inputs that differ in kind: the pointer or value far from where it was, at an edge, moving in the other direction, and across a boundary between groups.
   For each `finding` cell, state what the reader computes from the old value between the event and the next measurement, with concrete numbers. Trace two consecutive runs of the reader, not one: the first run after the event, and then the next run, after the first run's own result has been applied (whatever it moved has moved, the list has re-rendered) while some stored entries are still old. A reader that runs repeatedly during a gesture starts each run from what the previous run left behind. State how many staleness cells you traced.

**Measurements combined with counts.** List every computation that combines measured values with a logical count or index (the end of the list, the last item, the number of rows, an insertion index, a page number). For each one write a table of its result in each of these states: every item measured; only the first few measured (a long list, partly laid out); the first item not measured; the last item not measured; an empty list. In each row give the position it produces and the index it produces, and whether the two describe the same place. A row where they differ is a finding.

**Choosers.** For every function that picks one result among candidates (the nearest position, the first match, the best score, a default when nothing matches): list every result that the plan, docs, comments, tests or UI copy say a user can get, and for each one give a concrete input that makes the function return it. Then check the comparison itself: what happens on a tie, whether the comparison is strict, what value the running best starts from and whether each candidate can ever beat it, and whether two candidates can sit at the same position or score. A promised result that no input selects, or that can only be selected by overshooting and coming back, is a finding. Put the table in your report: result, where it is promised, the input that selects it, `executed` or `read`, verdict.

**Gesture exits and modes.** Check that every gesture ends on every exit: release, release outside the element, cancel by the system, blur, a second pointer, the screen unmounting, the data changing under it. For every animation or transition the change adds, write what is on screen at its start, middle and end in each mode the code branches on (reduced motion, a screen reader, large text). A step where the thing the user is watching is absent, doubled or in the wrong place is a finding.

**Checklist.** Coordinates mixed between spaces (screen, container, content with scroll offset); a scroll offset with more than one writer; a measurement taken before layout; a size or position captured once and reused after rotation, resize or text-size change; touch targets smaller or larger than what is drawn; auto-scroll that does not start, stop or re-evaluate when the pointer is still.

## What to report and what not to

Report every defect you observe in the changed behavior, including small ones: rate it Low, but do not drop it. If you noticed something wrong and can state the scenario, it belongs in the findings, not in a coverage note. A stale message, a hint that outlives its truth, or an error that stays after success are defects.

Do not report style, naming, comment wording, micro-performance, or speculative "a future caller could" concerns. Defects in code the change only moved should be listed separately as pre-existing.

## Report format

For each finding:
- Title and severity (High, Medium, Low, rated by consequence).
- Invariant: the rule being broken, in one sentence.
- Sites: every violating location as `file:line`, and the sibling sites you checked and found fine.
- Scenario: concrete inputs and state leading to the wrong outcome.
- Reach: what produces the scenario's starting condition in the application as it stands today (the screen, action, caller or stored data), as `file:line`. If you find nothing that produces it today, write `no trigger found today: needs <what would have to exist>`. Keep the finding either way: this line is for whoever ranks the findings, and it is not a reason to drop or soften one.
- Fix constraint: what a correct fix must guarantee, and the inverse failure it must not create.
- Verification: reproduced, ran a test, read source, or inferred from reading.

Include every table the passes ask for.

After the tables, write a finding-row index. Give one line for every table row or cell whose verdict is `finding`: the table, the row (and column), the number of the written finding that covers it, and a quotation of the sentence in that finding that says what goes wrong at that row's own reader, site or input. A written finding about a different reader, site or path of the same value does not cover the row, even when the cause is shared. If you cannot quote such a sentence, write a new finding for the row before you finish. State the number of `finding` rows and cells in your tables and the number of index lines; the two must be equal.

End with a coverage statement: the unit ledger, the passes you ran and what you enumerated for each, anything you ran, and what you did not check and why. Then the "Outside my focus" list.
