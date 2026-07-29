# Runbook: payments-api

**Owner:** payments

## Architecture

payments-api is a Go service behind an ALB. It writes to an Aurora PostgreSQL
cluster and publishes settlement events to SNS. Redis fronts the idempotency
key store. The service is deployed by Argo CD from the `acme/payments` repo.

## Monitoring

Check the dashboard if something looks wrong. Logs are in CloudWatch.

## Recovery objectives

- RTO: 15 minutes
- RPO: 5 minutes
