# bad-incident-suppression-no-reason

`incident-skill:ignore ARCH-DR-002` with no `-- reason` in the runbook's header,
on a stateful service (Aurora writer) whose recovery section says only "Stated in
the platform DR plan" with no RTO, no RPO, and no link.

Both fire: `META-SUP-001` for the unreasoned suppression and `ARCH-DR-002` for the
absent recovery objectives, because a suppression missing its reason does not
suppress anything.

Contrast `clean-incident-ready`, where the same rule is suppressed with a reason
that states the service is stateless and names the file where the upstream
objectives live. That reason is checkable. "Stated in the platform DR plan" with
no link is not, which is also why exclusion 3 does not rescue this case.

Everything else in the runbook is deliberately good so no other rule fires: the
paging alert has a resolving `runbook_url`, the runbook leads with mitigation, every
check is a runnable command with a branch, the dashboard and log group are named,
and escalation is a named schedule.
