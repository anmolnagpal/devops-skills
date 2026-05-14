#!/usr/bin/env bash
set -euo pipefail

# Report resources missing a required tag, grouped by service.
# Uses the Resource Groups Tagging API.

VERSION="0.1.0"
TAG_KEY=""
REGION=""
ALL_REGIONS=false

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") --tag-key <key> [options]

List resources missing a required tag, grouped by service. Useful before
allocating cost or driving a tagging cleanup campaign.

Required:
  --tag-key <key>     The tag key resources must have (e.g., Owner, CostCenter)

Options:
  --region <r>        Single region (default: current profile region)
  --all-regions       Scan all enabled regions (slow)
  -h, --help          Show this help
  -v, --version       Show version

Examples:
  $(basename "$0") --tag-key Owner
  $(basename "$0") --tag-key CostCenter --all-regions
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --tag-key) TAG_KEY="$2"; shift 2 ;;
        --region) REGION="$2"; shift 2 ;;
        --all-regions) ALL_REGIONS=true; shift ;;
        -h|--help) usage ;;
        -v|--version) echo "untagged-spend.sh v${VERSION}"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ -z "$TAG_KEY" ]] && { echo "Error: --tag-key is required" >&2; usage; }
command -v aws >/dev/null 2>&1 || { echo "aws CLI not found" >&2; exit 1; }

if $ALL_REGIONS; then
    REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)
elif [[ -n "$REGION" ]]; then
    REGIONS="$REGION"
else
    REGIONS=$(aws configure get region 2>/dev/null || echo "")
    [[ -z "$REGIONS" ]] && REGIONS="${AWS_REGION:-us-east-1}"
fi

for r in $REGIONS; do
    echo -e "${CYAN}── Region: ${r} ──${NC}"
    echo "Resources missing tag '${TAG_KEY}', by service:"
    echo

    # Get all tagged + untagged resources, then filter for those without the key.
    raw=$(aws resourcegroupstaggingapi get-resources --region "$r" \
        --resources-per-page 100 \
        --query 'ResourceTagMappingList[].[ResourceARN,Tags[?Key==`'"$TAG_KEY"'`].Value | [0]]' \
        --output text 2>/dev/null || true)

    if [[ -z "$raw" ]]; then
        echo -e "${GREEN}✓${NC} No resources visible (or all tagged) in ${r}"
        echo
        continue
    fi

    # Parse: ARNs without value (None or empty) are untagged.
    # Group by service (ARN field 2: arn:aws:<service>:...)
    echo "$raw" | awk -F'\t' '
        $2 == "None" || $2 == "" {
            split($1, p, ":")
            svc = p[3]
            count[svc]++
        }
        END {
            for (s in count) printf "  %-30s %d\n", s, count[s]
        }
    ' | sort -k2 -rn

    echo
done

echo -e "${BOLD}Note:${NC} this lists resources without the tag KEY. Use AWS Config rule"
echo "  'required-tags' or Tag Policies in AWS Organizations to enforce values too."
echo "For cost attribution, enable cost-allocation tags in the Billing console."
