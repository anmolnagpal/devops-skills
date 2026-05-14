#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building test image..."
docker build -f _test/Dockerfile -t devops-skills-test . 2>&1

echo ""
echo "Running test container..."
docker run --rm devops-skills-test

echo ""
echo "Test passed. Cleaning up image..."
docker rmi devops-skills-test --force > /dev/null 2>&1
