# payments platform

Two services: `checkout-api` accepts orders, `ledger-api` settles them.
Deployed to prod EKS with the Helm values under `deploy/`.

## Running locally

    go run ./checkout-api
    go run ./ledger-api
