# clean-github-docs-and-tests

Nothing may fire. The counterpart to `bad-github-missing-docs-tests`, satisfying each
of the three file-based rules by a different route so the pair isolates what each
checks.

- `REPO-DOC-001` — a `README.md` at the root.
- `REPO-DOC-002` — **no `CONTRIBUTING.md`**, deliberately. The rule needs a missing
  CONTRIBUTING *and* a missing runbook, and `docs/runbook-pricing.md` is present, so it
  must stay silent. A check that fires on a missing CONTRIBUTING alone fails this case,
  which is the point of leaving it out.
- `REPO-TEST-001` — satisfied twice over: `src/index.test.ts` beside the source, and
  `npm test` in the workflow. Either alone would clear it.

The `test` script now exists in `package.json`, which is the difference a reviewer
would notice first, though the rule keys on the test file and the workflow step rather
than on the script's presence.
