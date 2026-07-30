# Runbook: pricing

**Owner:** commerce · **Escalation:** PagerDuty COM-OC

## Mitigate first

If totals are wrong after a deploy, roll back:

    argocd app rollback pricing-prod
