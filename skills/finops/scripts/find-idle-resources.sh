#!/usr/bin/env bash
set -euo pipefail

# Find idle/orphaned AWS resources that cost money.
# Detects: unattached EBS, unused EIPs, idle ELBs, stopped EC2 (still paying for EBS),
# old snapshots, unattached ENIs, idle NAT gateways, log groups without retention.

VERSION="0.1.0"
REGION=""
ALL_REGIONS=false
SNAPSHOT_AGE_DAYS=90
ELB_IDLE_DAYS=14

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Find idle / orphaned AWS resources in the target account.

Options:
  --region <r>              Single region to scan (default: AWS_REGION or current profile region)
  --all-regions             Scan all enabled regions (slow but thorough)
  --snapshot-age <days>     Flag snapshots older than N days (default: 90)
  --elb-idle-days <days>    Flag ELBs idle for N days (default: 14)
  -h, --help                Show this help
  -v, --version             Show version

Requires: aws CLI v2, valid credentials (env, profile, or instance role).

Examples:
  $(basename "$0")
  $(basename "$0") --region us-east-1
  $(basename "$0") --all-regions --snapshot-age 30
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --region) REGION="$2"; shift 2 ;;
        --all-regions) ALL_REGIONS=true; shift ;;
        --snapshot-age) SNAPSHOT_AGE_DAYS="$2"; shift 2 ;;
        --elb-idle-days) ELB_IDLE_DAYS="$2"; shift 2 ;;
        -h|--help) usage ;;
        -v|--version) echo "find-idle-resources.sh v${VERSION}"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

command -v aws >/dev/null 2>&1 || { echo "aws CLI not found" >&2; exit 1; }

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${BOLD}Idle resource sweep — account ${ACCOUNT_ID}${NC}"
echo

if $ALL_REGIONS; then
    REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)
elif [[ -n "$REGION" ]]; then
    REGIONS="$REGION"
else
    REGIONS=$(aws configure get region 2>/dev/null || echo "")
    [[ -z "$REGIONS" ]] && REGIONS="${AWS_REGION:-us-east-1}"
fi

scan_region() {
    local r="$1"
    echo -e "${CYAN}── Region: ${r} ──${NC}"

    # Unattached EBS volumes
    local vols
    vols=$(aws ec2 describe-volumes --region "$r" \
        --filters Name=status,Values=available \
        --query 'Volumes[].[VolumeId,Size,VolumeType,CreateTime]' \
        --output text 2>/dev/null || true)
    if [[ -n "$vols" ]]; then
        local total=0
        echo -e "${YELLOW}Unattached EBS volumes:${NC}"
        while IFS=$'\t' read -r vid size vtype ctime; do
            [[ -z "$vid" ]] && continue
            printf "  %-22s %4s GiB  %-8s  %s\n" "$vid" "$size" "$vtype" "$ctime"
            total=$((total + size))
        done <<<"$vols"
        echo -e "  ${BOLD}Total: ${total} GiB unattached${NC}"
    else
        echo -e "${GREEN}✓${NC} No unattached EBS volumes"
    fi

    # Unused / unassociated Elastic IPs
    local eips
    eips=$(aws ec2 describe-addresses --region "$r" \
        --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' \
        --output text 2>/dev/null || true)
    if [[ -n "$eips" ]]; then
        echo -e "${YELLOW}Unassociated Elastic IPs:${NC}"
        echo "$eips" | awk '{printf "  %-16s  %s\n", $1, $2}'
    else
        echo -e "${GREEN}✓${NC} No unassociated EIPs"
    fi

    # Stopped EC2 (still paying for EBS)
    local stopped
    stopped=$(aws ec2 describe-instances --region "$r" \
        --filters Name=instance-state-name,Values=stopped \
        --query 'Reservations[].Instances[].[InstanceId,InstanceType,LaunchTime]' \
        --output text 2>/dev/null || true)
    if [[ -n "$stopped" ]]; then
        echo -e "${YELLOW}Stopped EC2 instances (EBS still billed):${NC}"
        echo "$stopped" | awk '{printf "  %-22s %-14s %s\n", $1, $2, $3}'
    else
        echo -e "${GREEN}✓${NC} No stopped EC2 instances"
    fi

    # Unattached ENIs
    local enis
    enis=$(aws ec2 describe-network-interfaces --region "$r" \
        --filters Name=status,Values=available \
        --query 'NetworkInterfaces[].[NetworkInterfaceId,Description]' \
        --output text 2>/dev/null || true)
    if [[ -n "$enis" ]]; then
        echo -e "${YELLOW}Unattached ENIs:${NC}"
        echo "$enis" | awk -F'\t' '{printf "  %-22s  %s\n", $1, $2}'
    else
        echo -e "${GREEN}✓${NC} No unattached ENIs"
    fi

    # Old snapshots
    local cutoff
    cutoff=$(date -u -v-${SNAPSHOT_AGE_DAYS}d +%Y-%m-%dT%H:%M:%S 2>/dev/null \
        || date -u -d "${SNAPSHOT_AGE_DAYS} days ago" +%Y-%m-%dT%H:%M:%S)
    local oldsnaps
    oldsnaps=$(aws ec2 describe-snapshots --region "$r" --owner-ids self \
        --query "Snapshots[?StartTime<='${cutoff}'].[SnapshotId,VolumeSize,StartTime]" \
        --output text 2>/dev/null || true)
    if [[ -n "$oldsnaps" ]]; then
        local count snap_total
        count=$(echo "$oldsnaps" | wc -l | tr -d ' ')
        snap_total=$(echo "$oldsnaps" | awk '{s+=$2} END {print s+0}')
        echo -e "${YELLOW}Snapshots older than ${SNAPSHOT_AGE_DAYS} days:${NC} ${count} snapshots, ${snap_total} GiB total"
    else
        echo -e "${GREEN}✓${NC} No snapshots older than ${SNAPSHOT_AGE_DAYS} days"
    fi

    # Idle Classic + ALB/NLB load balancers (heuristic via CloudWatch RequestCount/ActiveFlowCount)
    local lbs
    lbs=$(aws elbv2 describe-load-balancers --region "$r" \
        --query 'LoadBalancers[].[LoadBalancerArn,LoadBalancerName,Type]' \
        --output text 2>/dev/null || true)
    if [[ -n "$lbs" ]]; then
        echo -e "${YELLOW}Load balancers (check usage manually for those not seen below):${NC}"
        while IFS=$'\t' read -r arn name type; do
            [[ -z "$arn" ]] && continue
            printf "  %-50s %-8s %s\n" "$name" "$type" "$arn"
        done <<<"$lbs"
        echo "  (Cross-check CloudWatch RequestCount/ActiveFlowCount over last ${ELB_IDLE_DAYS}d)"
    fi

    # NAT Gateways (worth scrutinizing for low traffic)
    local nats
    nats=$(aws ec2 describe-nat-gateways --region "$r" \
        --filter Name=state,Values=available \
        --query 'NatGateways[].[NatGatewayId,VpcId,SubnetId]' \
        --output text 2>/dev/null || true)
    if [[ -n "$nats" ]]; then
        echo -e "${YELLOW}NAT Gateways (check BytesOutToDestination via CloudWatch):${NC}"
        echo "$nats" | awk '{printf "  %-22s %-22s %s\n", $1, $2, $3}'
    fi

    # CloudWatch log groups without retention
    local lgs
    lgs=$(aws logs describe-log-groups --region "$r" \
        --query 'logGroups[?retentionInDays==`null`].[logGroupName,storedBytes]' \
        --output text 2>/dev/null || true)
    if [[ -n "$lgs" ]]; then
        local lg_count lg_total
        lg_count=$(echo "$lgs" | wc -l | tr -d ' ')
        lg_total=$(echo "$lgs" | awk '{s+=$2} END {printf "%.2f", s/1024/1024/1024}')
        echo -e "${YELLOW}Log groups without retention policy:${NC} ${lg_count} groups, ${lg_total} GiB total"
    fi

    echo
}

for r in $REGIONS; do
    scan_region "$r"
done

echo -e "${BOLD}Sweep complete.${NC} For per-resource pricing, see Cost Explorer or query CUR."
