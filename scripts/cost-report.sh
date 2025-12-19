#!/bin/bash
# Copyright (c) 2024 Bima Kharisma Wicaksana
# Cost Report Generator Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ID="${PROJECT_ID:-}"
BILLING_ACCOUNT="${BILLING_ACCOUNT:-}"
DATASET="${DATASET:-billing_export}"

print_header() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}              GCP Cost Report Generator                        ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI not found${NC}"
        exit 1
    fi

    if ! command -v bq &> /dev/null; then
        echo -e "${RED}Error: bq (BigQuery CLI) not found${NC}"
        exit 1
    fi

    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$PROJECT_ID" ]; then
            echo -e "${RED}Error: PROJECT_ID not set and no default project configured${NC}"
            exit 1
        fi
    fi

    echo -e "${GREEN}✓ Prerequisites met${NC}"
    echo -e "${GREEN}✓ Project: $PROJECT_ID${NC}"
}

get_current_month_costs() {
    echo -e "\n${YELLOW}Current Month Costs by Service:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    bq query --use_legacy_sql=false --format=pretty "
    SELECT
        service.description AS service,
        ROUND(SUM(cost), 2) AS cost_usd
    FROM \`${PROJECT_ID}.${DATASET}.gcp_billing_export_v1_*\`
    WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_TRUNC(CURRENT_DATE(), MONTH))
    GROUP BY service
    ORDER BY cost_usd DESC
    LIMIT 15
    " 2>/dev/null || echo "No billing data available or BigQuery export not configured"
}

get_daily_trend() {
    echo -e "\n${YELLOW}Daily Cost Trend (Last 7 Days):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    bq query --use_legacy_sql=false --format=pretty "
    SELECT
        DATE(usage_start_time) AS date,
        ROUND(SUM(cost), 2) AS daily_cost_usd
    FROM \`${PROJECT_ID}.${DATASET}.gcp_billing_export_v1_*\`
    WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
    GROUP BY date
    ORDER BY date DESC
    " 2>/dev/null || echo "No billing data available"
}

get_cost_by_label() {
    echo -e "\n${YELLOW}Cost by Environment Label:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    bq query --use_legacy_sql=false --format=pretty "
    SELECT
        IFNULL(labels.value, 'unlabeled') AS environment,
        ROUND(SUM(cost), 2) AS cost_usd
    FROM \`${PROJECT_ID}.${DATASET}.gcp_billing_export_v1_*\`,
    UNNEST(labels) AS labels
    WHERE labels.key = 'environment'
        AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_TRUNC(CURRENT_DATE(), MONTH))
    GROUP BY environment
    ORDER BY cost_usd DESC
    " 2>/dev/null || echo "No labeled resources found"
}

get_recommendations() {
    echo -e "\n${YELLOW}Cost Optimization Recommendations:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Get regions with resources
    REGIONS=$(gcloud compute regions list --format="value(name)" 2>/dev/null | head -5)

    echo -e "\n${BLUE}VM Right-sizing Recommendations:${NC}"
    for region in $REGIONS; do
        gcloud recommender recommendations list \
            --project="$PROJECT_ID" \
            --location="$region" \
            --recommender=google.compute.instance.MachineTypeRecommender \
            --format="table(name.basename(),description,primaryImpact.costProjection.cost.units)" \
            2>/dev/null || true
    done

    echo -e "\n${BLUE}Idle Resource Recommendations:${NC}"
    for region in $REGIONS; do
        gcloud recommender recommendations list \
            --project="$PROJECT_ID" \
            --location="$region" \
            --recommender=google.compute.instance.IdleResourceRecommender \
            --format="table(name.basename(),description)" \
            2>/dev/null || true
    done

    echo -e "\n${BLUE}Committed Use Discount Recommendations:${NC}"
    gcloud recommender recommendations list \
        --project="$PROJECT_ID" \
        --location=global \
        --recommender=google.compute.commitment.UsageCommitmentRecommender \
        --format="table(name.basename(),description,primaryImpact.costProjection.cost.units)" \
        2>/dev/null || echo "No CUD recommendations available"
}

get_budget_status() {
    echo -e "\n${YELLOW}Budget Status:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -n "$BILLING_ACCOUNT" ]; then
        gcloud billing budgets list \
            --billing-account="$BILLING_ACCOUNT" \
            --format="table(displayName,amount.specifiedAmount.units,amount.specifiedAmount.currencyCode)" \
            2>/dev/null || echo "Unable to fetch budget information"
    else
        echo "BILLING_ACCOUNT not set. Set it to view budget status."
    fi
}

generate_summary() {
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                      Summary                                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

    # Get MTD total
    MTD_TOTAL=$(bq query --use_legacy_sql=false --format=csv --quiet "
    SELECT ROUND(SUM(cost), 2)
    FROM \`${PROJECT_ID}.${DATASET}.gcp_billing_export_v1_*\`
    WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_TRUNC(CURRENT_DATE(), MONTH))
    " 2>/dev/null | tail -1) || MTD_TOTAL="N/A"

    echo -e "Month-to-Date Total: ${BLUE}\$${MTD_TOTAL}${NC}"

    # Get yesterday's cost
    YESTERDAY=$(bq query --use_legacy_sql=false --format=csv --quiet "
    SELECT ROUND(SUM(cost), 2)
    FROM \`${PROJECT_ID}.${DATASET}.gcp_billing_export_v1_*\`
    WHERE DATE(usage_start_time) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    " 2>/dev/null | tail -1) || YESTERDAY="N/A"

    echo -e "Yesterday's Cost: ${BLUE}\$${YESTERDAY}${NC}"

    # Calculate projected monthly cost
    DAY_OF_MONTH=$(date +%d)
    DAYS_IN_MONTH=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%d 2>/dev/null || echo 30)

    if [ "$MTD_TOTAL" != "N/A" ] && [ "$DAY_OF_MONTH" -gt 0 ]; then
        PROJECTED=$(echo "scale=2; $MTD_TOTAL / $DAY_OF_MONTH * $DAYS_IN_MONTH" | bc 2>/dev/null || echo "N/A")
        echo -e "Projected Monthly: ${BLUE}\$${PROJECTED}${NC}"
    fi
}

# Main
print_header
check_prerequisites

case "${1:-all}" in
    costs)
        get_current_month_costs
        ;;
    daily)
        get_daily_trend
        ;;
    labels)
        get_cost_by_label
        ;;
    recommendations)
        get_recommendations
        ;;
    budget)
        get_budget_status
        ;;
    summary)
        generate_summary
        ;;
    all)
        get_current_month_costs
        get_daily_trend
        get_cost_by_label
        get_budget_status
        get_recommendations
        generate_summary
        ;;
    *)
        echo "Usage: $0 {costs|daily|labels|recommendations|budget|summary|all}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Report generated at: $(date)${NC}"
