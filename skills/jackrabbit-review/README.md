# jackrabbit-review

A review of the current branch by five reviewers with different focuses, merged and then checked
against the code. Invoke it as `/jackrabbit-review` from the repository to review, or ask for a
jackrabbit review by name.

- `SKILL.md`: the orchestration.
- `help.md`: what `/jackrabbit-review help` shows. Keep it in step with `SKILL.md`.
- `jackrabbit-review-config.yaml`: the default settings; `scripts/settings.sh` layers the
  user's and the repository's settings files over it.
- `prompts/lens-{state,data,boundary,conformance,geometry}.md`: the five reviewer prompts. A
  change to them is tested against recorded cases before it is kept (`update-jackrabbit-review`).
- `prompts/merge.md`: combines the five reports without dropping anything.
- `prompts/verify.md`: tries to refute each merged finding against the code and settles reach.
- `scripts/prepare.sh`, `scripts/verify-batches.sh`: resolve the base, create the run directory
  inside the reviewed repository's git directory, render the prompts.
- `opencode/jackrabbit-reviewer.md`: the opencode agent the stages run on, without a fixed
  model. Copy it to `~/.config/opencode/agent/`.
