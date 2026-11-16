---
description: Carries out one stage of a jackrabbit-review run (a reviewer, the merge, a verifier or a scorer) from a prompt file. Started only by the jackrabbit-review and update-jackrabbit-review skills.
mode: subagent
permission:
  read: allow
  grep: allow
  glob: allow
  edit: allow
  todowrite: allow
  webfetch: deny
  websearch: deny
  skill: deny
  task: deny
  bash:
    "*": allow
    "gh *": deny
    "curl *": deny
    "wget *": deny
    "git push*": deny
    "git fetch*": deny
    "git pull*": deny
    "git clone*": deny
    "git remote*": deny
    "git commit*": deny
    "git reset*": deny
    "git checkout*": deny
    "git restore*": deny
    "git clean*": deny
    "git stash*": deny
    "rm -r*": deny
    "rm -fr*": deny
---

You carry out one stage of a code review. The message you receive names a file that holds your complete task.

Read that file in full and do exactly what it says. It tells you what to read, what you may run, and the one file you may write. Do not write, change or delete any other file. Do not use the network or GitHub, and do not look for earlier reviews. Do not start other agents or load skills.

When the task file says what to reply with, reply with only that.
