# bad-finops-waiver-no-reason

One finding. The first `COST-DB-001` waiver has no `reason`, so it suppresses nothing
and is itself `META-SUP-001`.

The second entry is the control: `COST-STOR-003` carries a real reason (gp2 boot
volumes on a vendor appliance), so it must be honored silently and must **not** raise
`META-SUP-001`. One malformed entry in a file does not invalidate the others.

## Why this suite is one rule wide

Every other rule in this skill's catalog comes from live AWS billing and optimizer
data (Cost Explorer, CUR, Compute Optimizer), which the fixture harness cannot
provide, and the skill body says so explicitly. That is a real limit rather than
missing work: a `COST-COMP-001` finding is "Compute Optimizer says this instance is
over-provisioned", and no `.tf` file can stand in for that.

The waiver mechanism is the exception, because it is a file in the repo. So this suite
covers exactly the part that is checkable and makes no claim about the rest. The
alternative was leaving the skill with no suite at all, which reads as an oversight
rather than a boundary.
