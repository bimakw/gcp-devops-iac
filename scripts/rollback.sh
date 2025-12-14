#!/bin/bash
# Copyright (c) 2024 Bima Kharisma Wicaksana
# Rollback Script for Emergency Recovery
#
# Usage: ./rollback.sh <environment> [revision]
# Example: ./rollback.sh prod
# Example: ./rollback.sh prod 3

set -e

ENV=${1:-dev}
REVISION=${2:-}
NAMESPACE="app-${ENV}"
DEPLOYMENT="${ENV}-app"

echo "============================================"
echo "Rollback for ${ENV} environment"
echo "============================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Show current status
echo "=== Current Deployment Status ==="
kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o wide
echo ""

# Show rollout history
echo "=== Rollout History ==="
kubectl rollout history deployment/${DEPLOYMENT} -n ${NAMESPACE}
echo ""

# Perform rollback
if [ -n "${REVISION}" ]; then
    echo -e "${YELLOW}Rolling back to revision ${REVISION}...${NC}"
    kubectl rollout undo deployment/${DEPLOYMENT} -n ${NAMESPACE} --to-revision=${REVISION}
else
    echo -e "${YELLOW}Rolling back to previous revision...${NC}"
    kubectl rollout undo deployment/${DEPLOYMENT} -n ${NAMESPACE}
fi

# Wait for rollback to complete
echo ""
echo "Waiting for rollback to complete..."
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=300s

# Show new status
echo ""
echo "=== New Deployment Status ==="
kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o wide
echo ""

# Show pods
echo "=== Pod Status ==="
kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=app
echo ""

echo -e "${GREEN}Rollback completed successfully!${NC}"
