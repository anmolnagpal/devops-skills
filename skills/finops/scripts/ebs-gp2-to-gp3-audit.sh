#!/usr/bin/env bash
set -euo pipefail

# Audit gp2 EBS volumes and estimate monthly savings if migrated to gp3.
# Optionally perform the online migration with --apply (asks for confirmation per volume).

VERSION="0.1.0"
REGION=""
ALL_REGIONS=false
APPLY=false

# Illustrative US-East pricing (per GB-month). Override with --gp2-price/--gp3-price if needed.
GP2_PRICE=0.10
GP3_PRICE=0.08

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

List all gp2 EBS volumes and estimate monthly savings from migrating to gp3.
Optionally perform the online migration (no downtime) with --apply.

Options:
  --region <r>          Single region (default: AWS_REGION or current profile region)
  --all-regions         Scan all enabled regions
  --apply               Perform the migration. Asks per-volume confirmation.
  --gp2-price <p>       Override gp2 price per GB-month (default: ${GP2_PRICE})
  --gp3-price <p>       Override gp3 price per GB-month (default: ${GP3_PRICE})
  -h, --help            Show this help
  -v, --version         Show version

Notes:
  - gp3 base perf (3000 IOPS + 125 MB/s) is included with any size.
  - For volumes that need >3000 IOPS or >125 MB/s, gp3 may need provisioned extras
    that this audit does not estimate. Compute Optimizer EBS recommendations are
    more precise; use this script as a fast first pass.

Examples:
  $(basename "$0")
  $(basename "$0") --all-regions
  $(basename "$0") --region us-east-1 --apply
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --region) REGION="$2"; shift 2 ;;
        --all-regions) ALL_REGIONS=true; shift ;;
        --apply) APPLY=true; shift ;;
        --gp2-price) GP2_PRICE="$2"; shift 2 ;;
        --gp3-price) GP3_PRICE="$2"; shift 2 ;;
        -h|--help) usage ;;
        -v|--version) echo "ebs-gp2-to-gp3-audit.sh v${VERSION}"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

command -v aws >/dev/null 2>&1 || { echo "aws CLI not found" >&2; exit 1; }

if $ALL_REGIONS; then
    REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)
elif [[ -n "$REGION" ]]; then
    REGIONS="$REGION"
else
    REGIONS=$(aws configure get region 2>/dev/null || echo "")
    [[ -z "$REGIONS" ]] && REGIONS="${AWS_REGION:-us-east-1}"
fi

GRAND_TOTAL_SAVINGS=0
GRAND_TOTAL_VOLS=0
GRAND_TOTAL_GB=0

for r in $REGIONS; do
    echo -e "${CYAN}── Region: ${r} ──${NC}"

    vols=$(aws ec2 describe-volumes --region "$r" \
        --filters Name=volume-type,Values=gp2 \
        --query 'Volumes[].[VolumeId,Size,State,Iops]' \
        --output text 2>/dev/null || true)

    if [[ -z "$vols" ]]; then
        echo -e "${GREEN}✓${NC} No gp2 volumes in ${r}"
        echo
        continue
    fi

    region_total_gb=0
    region_savings=0
    region_count=0

    printf "%-22s %6s %-10s %6s %12s\n" "VolumeId" "GiB" "State" "IOPS" "Save/mo (\$)"
    while IFS=$'\t' read -r vid size state iops; do
        [[ -z "$vid" ]] && continue
        savings=$(awk -v s="$size" -v g2="$GP2_PRICE" -v g3="$GP3_PRICE" \
            'BEGIN { printf "%.2f", s * (g2 - g3) }')
        printf "%-22s %6s %-10s %6s %12s\n" "$vid" "$size" "$state" "$iops" "$savings"
        region_total_gb=$((region_total_gb + size))
        region_count=$((region_count + 1))
        region_savings=$(awk -v a="$region_savings" -v b="$savings" 'BEGIN {printf "%.2f", a+b}')
    done <<<"$vols"

    echo
    echo -e "  ${BOLD}${region_count} gp2 volumes, ${region_total_gb} GiB total, est. \$${region_savings}/month savings${NC}"
    echo

    GRAND_TOTAL_VOLS=$((GRAND_TOTAL_VOLS + region_count))
    GRAND_TOTAL_GB=$((GRAND_TOTAL_GB + region_total_gb))
    GRAND_TOTAL_SAVINGS=$(awk -v a="$GRAND_TOTAL_SAVINGS" -v b="$region_savings" 'BEGIN {printf "%.2f", a+b}')

    if $APPLY; then
        echo -e "${YELLOW}--apply was passed. Migrating gp2 → gp3 for region ${r}...${NC}"
        while IFS=$'\t' read -r vid size state iops; do
            [[ -z "$vid" ]] && continue
            read -r -p "Migrate ${vid} (${size} GiB)? [y/N] " ans </dev/tty
            if [[ "$ans" =~ ^[Yy]$ ]]; then
                aws ec2 modify-volume --region "$r" --volume-id "$vid" --volume-type gp3 \
                    --output table --query 'VolumeModification.[VolumeId,ModificationState,TargetVolumeType]'
            else
                echo "Skipped ${vid}"
            fi
        done <<<"$vols"
    fi
done

echo -e "${BOLD}Total: ${GRAND_TOTAL_VOLS} gp2 volumes, ${GRAND_TOTAL_GB} GiB, est. \$${GRAND_TOTAL_SAVINGS}/month savings${NC}"
$APPLY || echo -e "${CYAN}Run with --apply to perform the online migration (no downtime).${NC}"
