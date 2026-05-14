#!/usr/bin/env bash
set -euo pipefail

# Report current reservation coverage and utilization across reservable services,
# plus reservations expiring within a configurable window.
# Covers: Compute Savings Plans, EC2 RIs, RDS RIs, ElastiCache reserved nodes,
# OpenSearch reserved instances, Redshift reserved nodes.

VERSION="0.1.0"
SERVICE="all"
EXPIRING_DAYS=30
LOOKBACK_DAYS=30

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Report reservation coverage, utilization, and expirations across reservable AWS services.

Options:
  --service <s>         Limit to one service: ec2 | sp | rds | elasticache | opensearch | redshift | all (default: all)
  --expiring-days <n>   Window for "expiring soon" report (default: 30)
  --lookback-days <n>   Lookback for utilization metrics (default: 30)
  -h, --help            Show this help
  -v, --version         Show version

Requires: aws CLI v2 with ce: and reservation describe permissions.

Examples:
  $(basename "$0")
  $(basename "$0") --service rds
  $(basename "$0") --expiring-days 60
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --service) SERVICE="$2"; shift 2 ;;
        --expiring-days) EXPIRING_DAYS="$2"; shift 2 ;;
        --lookback-days) LOOKBACK_DAYS="$2"; shift 2 ;;
        -h|--help) usage ;;
        -v|--version) echo "reservation-coverage.sh v${VERSION}"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

command -v aws >/dev/null 2>&1 || { echo "aws CLI not found" >&2; exit 1; }

# Date math (macOS BSD vs GNU date)
today=$(date -u +%Y-%m-%d)
start=$(date -u -v-${LOOKBACK_DAYS}d +%Y-%m-%d 2>/dev/null \
    || date -u -d "${LOOKBACK_DAYS} days ago" +%Y-%m-%d)
expiring_until=$(date -u -v+${EXPIRING_DAYS}d +%Y-%m-%dT%H:%M:%S 2>/dev/null \
    || date -u -d "+${EXPIRING_DAYS} days" +%Y-%m-%dT%H:%M:%S)

run_for() { [[ "$SERVICE" == "all" || "$SERVICE" == "$1" ]]; }

# Savings Plans (Compute / EC2 Instance / SageMaker)
if run_for sp; then
    echo -e "${CYAN}── Savings Plans ──${NC}"
    echo "Coverage (last ${LOOKBACK_DAYS} days):"
    aws ce get-savings-plans-coverage \
        --time-period "Start=${start},End=${today}" \
        --query 'SavingsPlansCoverages[].{date:TimePeriod.Start,coverage:Coverage.CoveragePercentage,onDemand:Coverage.OnDemandCost,SP:Coverage.SpendCoveredBySavingsPlans}' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no SP coverage data)${NC}"

    echo "Utilization (last ${LOOKBACK_DAYS} days):"
    aws ce get-savings-plans-utilization \
        --time-period "Start=${start},End=${today}" \
        --query 'Total.{Util:Utilization.UtilizationPercentage,Used:Utilization.UsedCommitment,Total:Utilization.TotalCommitment,Saved:Savings.NetSavings}' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no SP utilization data)${NC}"

    echo "Active Savings Plans (expiring within ${EXPIRING_DAYS} days highlighted):"
    aws savingsplans describe-savings-plans --states active \
        --query 'savingsPlans[].[savingsPlanId,savingsPlanType,commitment,end]' \
        --output text 2>/dev/null | while IFS=$'\t' read -r id type commit endts; do
            [[ -z "$id" ]] && continue
            short=$(echo "$endts" | cut -c1-10)
            if [[ "$short" < "${expiring_until:0:10}" ]]; then
                echo -e "  ${RED}EXPIRING${NC}  $id  $type  \$${commit}/hr  ends ${short}"
            else
                echo "  active    $id  $type  \$${commit}/hr  ends ${short}"
            fi
        done
    echo
fi

# EC2 Reserved Instances
if run_for ec2; then
    echo -e "${CYAN}── EC2 Reserved Instances ──${NC}"
    aws ec2 describe-reserved-instances --filters Name=state,Values=active \
        --query 'ReservedInstances[].[ReservedInstancesId,InstanceType,InstanceCount,Scope,OfferingClass,End]' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no active EC2 RIs)${NC}"
    echo "RI Coverage:"
    aws ce get-reservation-coverage --time-period "Start=${start},End=${today}" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'CoveragesByTime[0].Groups[?Attributes.service==`Amazon Elastic Compute Cloud - Compute`].Coverage.CoverageHours' \
        --output table 2>/dev/null || true
    echo
fi

# RDS Reserved Instances
if run_for rds; then
    echo -e "${CYAN}── RDS Reserved Instances ──${NC}"
    aws rds describe-reserved-db-instances \
        --query 'ReservedDBInstances[?State==`active`].[ReservedDBInstanceId,DBInstanceClass,DBInstanceCount,MultiAZ,ProductDescription,Duration,StartTime]' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no active RDS RIs)${NC}"
    echo "RDS RI coverage:"
    aws ce get-reservation-coverage --time-period "Start=${start},End=${today}" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'CoveragesByTime[0].Groups[?Attributes.service==`Amazon Relational Database Service`].Coverage' \
        --output json 2>/dev/null || true
    echo
fi

# ElastiCache Reserved Nodes
if run_for elasticache; then
    echo -e "${CYAN}── ElastiCache Reserved Nodes ──${NC}"
    aws elasticache describe-reserved-cache-nodes \
        --query 'ReservedCacheNodes[?State==`active`].[ReservedCacheNodeId,CacheNodeType,CacheNodeCount,ProductDescription,Duration,StartTime]' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no active ElastiCache reserved nodes)${NC}"
    echo
fi

# OpenSearch Reserved Instances
if run_for opensearch; then
    echo -e "${CYAN}── OpenSearch Reserved Instances ──${NC}"
    aws opensearch describe-reserved-instances \
        --query 'ReservedInstances[?State==`active`].[ReservedInstanceId,InstanceType,InstanceCount,Duration,StartTime]' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no active OpenSearch RIs)${NC}"
    echo
fi

# Redshift Reserved Nodes
if run_for redshift; then
    echo -e "${CYAN}── Redshift Reserved Nodes ──${NC}"
    aws redshift describe-reserved-nodes \
        --query 'ReservedNodes[?State==`active`].[ReservedNodeId,NodeType,NodeCount,Duration,StartTime]' \
        --output table 2>/dev/null || echo -e "${YELLOW}(no active Redshift reserved nodes)${NC}"
    echo
fi

echo -e "${BOLD}Done.${NC} For purchase recommendations:"
echo "  aws ce get-savings-plans-purchase-recommendation --savings-plans-type COMPUTE_SP --term-in-years ONE_YEAR --payment-option NO_UPFRONT --lookback-period-in-days THIRTY_DAYS"
echo "  aws ce get-reservation-purchase-recommendation --service \"Amazon Relational Database Service\" --term-in-years ONE_YEAR --payment-option NO_UPFRONT --lookback-period-in-days THIRTY_DAYS"
