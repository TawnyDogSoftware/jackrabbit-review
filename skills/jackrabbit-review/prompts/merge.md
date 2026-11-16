You are combining several code reviews of the same change into one review. Each review was written by a reviewer with a different focus. The reviews are in these files:

{{REPORTS}}

Ground rules:
- Work only from those files. Do not open the repository, do not use the network, and do not look for other reviews.
- Do not modify those files.
- Save the combined review to `{{OUT}}`. That is the only file you may write. Then reply with only the word `saved`. Write the review for someone who will fix what it reports without asking questions and without reading the source reviews.

Your job is to lose nothing. You are not a second judge: you did not read the code, so you cannot overrule a reviewer who did.

## How to work

1. Read every file in full, including every table and the "Outside my focus" list at the end of each.

2. Build a ledger with one line per item, numbered, before you write anything else. An item is any of:
   - a written finding;
   - a table row whose verdict is `finding`, whether or not the reviewer also wrote it up;
   - a table row or sentence that describes a wrong outcome and then excuses it (for example "self-corrects", "rare", "may be intentional", "in practice", "only for one frame", "covered elsewhere" where the other place does not state it);
   - a line under "Outside my focus";
   - a design question;
   - a pre-existing defect.
   Record for each: source file and the reviewer's own number or table name, the code location, and the mechanism in a few words. State the ledger's item count per source file.

3. Group ledger items that describe the same mechanism at the same code path into one combined finding. Two items belong together only when one fix would close both. Same file with a different failure is a different finding. When in doubt, keep them separate.
   A table row or cell with verdict `finding` belongs to a written finding only if that finding's text says what goes wrong at the row's own reader, site or input. Reviewers often point a row at a finding that describes a different reader or path of the same value. Check the text, not the pointer (a reviewer's finding-row index, if present, quotes the sentence it relies on; judge that sentence the same way). If the text does not cover the row, make the row its own combined finding: title it from the row, give everything the row and its table say, and add the line "Not written up by the reviewer: the failure at this site still needs to be traced."

4. Write each combined finding with the union of what the grouped items say: every site, every scenario, every sibling location checked, every fix constraint and every inverse failure. Keep concrete values, row counts and `file:line` references exactly as the reviewers wrote them. Do not shorten a scenario to a summary. Keep every reviewer's Reach line, marked with the reviewer it came from. When the lines disagree (one names a trigger that exists today, another says there is none), keep both and say that they disagree; do not choose between them.

5. Conflicts. When one reviewer reports a mechanism and another marks the same code as holding, the finding stays. Add one line: which reviewer disagreed and the reason they gave. Never drop or downgrade a finding because another reviewer did not see it.

6. Severity is the highest any reviewer gave. An item that a reviewer described and then excused is listed as a finding at Low, with the excuse quoted in one clause.

7. Items that appear only under "Outside my focus" and that no other reviewer investigated go into their own section, "Leads not investigated", each with its location and the one-line description, so a person can check them.

8. Before finishing, go through the ledger number by number and write where each item ended up (combined finding number, lead, design question, or pre-existing). Every ledger number must appear exactly once. If one is missing, add it.

## Output format

1. Findings, ordered by severity and numbered F1, F2, F3 and so on. Each starts with a heading of exactly this form: `### F1. <title> (<severity>)`. Each has: invariant; sites; scenarios; reach, as each reviewer stated it; fix constraint and inverse failure; verification as the reviewers stated it; sources (which reviewer and item).
2. Leads not investigated.
3. Design questions.
4. Pre-existing defects.
5. The ledger map from step 8, one line per ledger item.
6. One line with the counts: ledger items, combined findings, leads.
