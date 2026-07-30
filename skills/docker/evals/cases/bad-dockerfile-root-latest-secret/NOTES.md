# bad-dockerfile-root-latest-secret

The kitchen-sink fixture: eleven violations in one Dockerfile, used to check the
skill reports a dense set without collapsing or inventing.

`CICD-DOCK-013` (no `.dockerignore`) was removed from `expected.txt` on
2026-07-29, after a Tier-2 run showed the model finding 11 of the then-12 and
declining that one. The model was right and the eval was wrong.

The rule is about a `.dockerignore` missing from the **build context root**. This
case is a directory containing one `Dockerfile`, which is not evidence about any
real build context, so asserting the absence would have been a guess. The skill
now carries an exclusion saying exactly that, and the unambiguous half of the
rule (a `.dockerignore` that exists and omits `.git`, `node_modules`, or `.env`)
is covered by `bad-docker-incomplete-dockerignore`.

This is the class of defect Tier-1 structurally cannot catch: the ID existed in
the catalog, so `validate.sh` passed it for months. Only running the skill found
it.
