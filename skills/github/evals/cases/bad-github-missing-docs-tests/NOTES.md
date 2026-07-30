# bad-github-missing-docs-tests

The first fixture suite this skill has had. Only three of its rules are checkable from
a checked-out repo; the rest need live GitHub state via `gh api` and cannot be
fixtured. This case covers those three and claims nothing about the others.

- `REPO-DOC-001` — no `README.md`, `README.rst`, or `README` at the root.
- `REPO-DOC-002` — no `CONTRIBUTING.md`, and no runbook anywhere: no `RUNBOOK.md`, no
  `docs/runbook*.md`, no `docs/operations*.md`. The rule needs **both** absent, which
  is why the fixture has no `docs/` directory at all.
- `REPO-TEST-001` — no test directory or config (`test/`, `tests/`, `spec/`,
  `__tests__/`, no `*.test.ts` beside `src/index.ts`, no `jest.config.*`) **and** no
  test step in the workflow. The workflow deliberately runs `lint` and `build` and
  stops there, because either signal alone would clear the rule.

The workflow is otherwise correct so nothing else fires: actions SHA-pinned with
version comments, a `contents: read` permissions baseline, a concurrency group, a
timeout, and `cache: npm`.

Note the `package.json` declares `build` and `lint` scripts and no `test` script. That
is the detail worth catching: a repo with a full CI pipeline and no test coverage looks
maintained from the outside.
