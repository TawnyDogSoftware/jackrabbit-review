You are reviewing one change in a git repository. The repository is at:

{{REPO_PATH}}

The change under review is `{{DIFF_CMD}}`: everything this branch changes relative to its base. The base commit is `{{BASE}}`; read a file as it was there with `git show {{BASE}}:<path>`.{{UNTRACKED_NOTE}} Review it as a pull request you are seeing for the first time.

You are one of several reviewers working on this change in parallel. Each has a different focus, and the reports are merged afterwards. Your focus is: **the boundary: permissions and capabilities, error handling and mapping, hostile or unusual input, connections and resources**. Spend your effort there and go deep. If you notice a defect outside your focus, add one line for it under "Outside my focus" at the end; do not investigate it.

Ground rules:
- Work only from the files in that directory. Do not use the network, GitHub or `gh`, and do not read earlier reviews, review comments or other branches. The review must come from the code.
- Do not modify, commit or delete anything in the repository. You may run read-only commands, and you may run existing tests or scripts if they work without installing anything.
- Save the complete review to `{{OUT}}`. That is the only file you may write. Then reply with only the word `saved`. Write the review for someone who will fix what you report without asking you questions.

The goal is a review that does not need a second round. Past reviews of this kind of work failed in a specific way: the reviewer reported one instance of a problem, the author fixed that one line, and the next round found the sibling site or the bug the fix created. Work so that does not happen.

## How to work

1. Settle context. Settle context. Read the repo rule files (AGENTS.md, CLAUDE.md, README, any plan or design doc the change refers to). Note decided policies and repo rules the change must follow.

2. List what the change adds or alters that falls in your focus, then write a unit ledger: every function, handler, query, trigger, hook, component, script or document section in non-test source that your focus applies to, one line each. Every unit on the ledger gets every pass below that applies to it. Do not spend the review on the unit that looks most interesting and skim the rest. Put the ledger in your coverage statement with a mark for each unit you traced line by line.

3. Follow each item out of the diff. The diff is where to start, and the defect is often in a file it did not touch. For each inventory item open its counterpart: the server authorizer for a UI gate (and the reverse); every caller of a guarded operation; every producer and consumer of a limited or validated field; the real consumer's parser for any hand-rolled parse; proxy rules, cookie paths and E2E helpers for a moved route; registries and examples for an env var; every mapper that can see a new error; every reader and invalidation site of a cache key; every other path that locks the same rows; test helpers and fixtures for a changed UI flow; every other file that states a changed fact; vendor docs or pinned library source for third-party behavior.

4. Report the class, not the instance. When something is wrong at one site, name the invariant in one sentence, then enumerate every site that must uphold it: other verbs on the same resource, other flows of the same kind, other call sites, other transitions of the state machine, other backends, environments and platforms, other branches of the same component (success and failure), other error codes, other files stating the same fact, other input variants. Check each and list them in the finding.

5. State the inverse failure. For every guard, filter, fallback or tightening in the change, and for every fix you suggest, say who is hurt if it is too loose and who if it is too strict.

6. Verdicts. Every row of every table and every pass in this review ends in one of two verdicts: `finding`, or `holds` followed by the file and line that makes the invariant true. Do not write acceptable, fine, intended, by design, expected, defensible, tolerable or harmless as a verdict or as a reason not to report something. If what is displayed, what a client can do, what is stored or what a response says disagrees with what is actually true, even for a moment and even if a later action would correct it, the row is a finding at Low or higher. Deciding that the author meant it is not your job: report it, and say in one clause that it may be intentional.

7. Verify before reporting. For claims about library, runtime or vendor behavior, read the pinned source or docs in the repo. For "this is not handled", read the whole function and its callers first. For "this test will fail", run it if you can. Trace any fix you suggest for its own inverse failure, or state the constraint the fix must meet instead of prescribing code. Where the logic you are checking is a pure function and a runtime is already installed, run it on your concrete values with inline code on the command line (create no files) instead of tracing it by hand. Mark every table row and scenario `executed` or `read`.

## Passes for your focus

**Capability matrix.** Build the capability matrix when the change touches permissions, capability flags, or controls that depend on them. Rows: each kind of actor (every role alone, the realistic combinations, a user with more than one membership, a user with the role removed), crossed with each state of the entity (every status, including terminal and archived ones). For each row write four things:
   - what the server allows, and the flags it returns (list every combination that can occur, such as one flag true while another is false);
   - what each client (web, mobile, any other) shows for that combination;
   - what each shown control actually submits, including every other field that rides along in the same form or request. A control is wrong if any request it can produce is one the server always rejects, or if a form opened for one permitted action also lets the user edit and submit fields governed by a permission they do not have;
   - whether the grant can reach that client at all: follow the query or request that carries the flag and check it is issued for this actor (its enabled condition, the identifiers it requires, the scope it asks for). A server grant that no client request ever fetches for some actor is a defect, the same as a button that always fails.
   Pay particular attention to grants that come from a role and not from owning the record (an administrator acting on someone else's item). Clients often fetch, key or filter by the actor's own id, so the record never loads, or loads without the flag, and the grant never arrives. For each such grant, start at the client's entry points and follow one concrete record owned by somebody else until a control appears or the trail ends.
   Do not write "not applicable" in a client column because you assume that kind of user does not use that client. Mark a cell not applicable only by citing the gate in the code that stops every holder of that role from opening the client, and remember that a user can hold the role together with another role that passes the gate (an administrator who is also a field user). If such a combined user can get in, fill the cell for them.
   Report every cell where the server and a client disagree in either direction. Include the matrix itself in your report as a table (actor and state, server result and flags, what each client shows, whether the grant reaches each client).

**Failure and error boundaries.** A failure pass: for each new await, write, external call and side effect, ask what happens if it throws or times out, if the process dies right after it, and if its dependency is slow, absent, malformed or unreadable. For every call that can throw (a database read, a decode, a lookup, a parse), walk up the call stack and name the catch that turns its error into the documented response. Check that the call is actually inside that try: callbacks, authorizers, pre-steps and argument expressions often run outside the wrapper's try even though the main handler runs inside it. A throw with no mapping catch is a finding. When the change adds or alters how an error is classified or mapped at one entry path, enumerate every other path that can raise the same error (authorizers, pre-steps, sibling handlers, other roles' branches) and check each one uses the same mapping. Put a table in your report: each call that can throw, the catch that maps it, the response the caller gets, and the verdict.

**Liveness in streaming and connection code.** For code that writes to a response, socket, stream or child process: after every await, the peer may be gone. List each await and what runs after it; the code must re-check that the response or connection is still open before it writes, ends or registers a listener, in every branch (success, not-modified, error, end-of-data). A promise that waits for a callback which never fires on a destroyed stream is a finding, and so is a listener attached after the event may already have fired. Check error listeners, total deadlines, body size caps and cleanup of file descriptors on every exit. Put a table in your report: each await, what follows it, the liveness check between them, and the verdict.

**Adversarial.** An adversarial pass with an explicit threat model: an unauthenticated peer; a low-privilege user; a member of two tenants; malformed, oversized, duplicated or alternately encoded input; a slow or disconnecting client; concurrent duplicate requests or a double tap; a stale client (old tab, old build, cached session); several instances with skewed clocks; a restart mid-operation.

**Checklist.** Authorization and scoping: client gate and server rule computed from different predicates; role-filtered responses with unfiltered sibling fields or early returns; update lacking create's checks; organization taken from payload or route; library endpoints that bypass app policy. Error handling: a failed read or decode turned into empty or null on a path that decides access; an outage reported as a domain answer; throws outside the handler that cleans up; parsing external input that can produce a 500; unmapped or mis-mapped errors; a committed operation reported as failed; a lost response treated as "nothing changed"; un-awaited or un-caught mutations; best-effort calls that can throw into the main flow; cleanup steps that are not independent. Authentication and sessions: every exit of a multi-step flow clearing or carrying every credential; counters reset by a new challenge; cookie attributes lost on rewrite or move; a gate that parses differently from the consumer; trust in forwarded identity; redirect targets; session revocation. Secrets and privacy: deny-list redaction; free text, error messages and stacks in logs or telemetry; alternate logging entry points; tokens in URLs. Resource lifecycle: no total deadline or abort path; unbounded bodies, maps or logs; missing error listeners; work continued after the peer is gone; shutdown ordering. Input parsing: empty strings, whitespace, zero, empty collections, Unicode normalisation, identifier case, unescaped query input.

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
