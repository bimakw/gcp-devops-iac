#!/bin/bash
# Copyright (c) 2024 Bima Kharisma Wicaksana
# Smoke Test Script for Environment Validation
#
# Usage: ./smoke-test.sh <environment>
# Example: ./smoke-test.sh dev

set -e

ENV=${1:-dev}
NAMESPACE="app-${ENV}"
SERVICE_NAME="${ENV}-app"

echo "============================================"
echo "Running smoke tests for ${ENV} environment"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Test function
run_test() {
    local test_name=$1
    local test_command=$2

    echo -n "Testing: ${test_name}... "

    if eval "${test_command}" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

# Get service endpoint
get_service_endpoint() {
    kubectl get svc ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.clusterIP}'
}

echo "=== Infrastructure Tests ==="
echo ""

# Test 1: Namespace exists
run_test "Namespace exists" "kubectl get namespace ${NAMESPACE}"

# Test 2: Deployment exists and has ready replicas
run_test "Deployment is ready" "kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}' | grep -v '^0$'"

# Test 3: Pods are running
run_test "Pods are running" "kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=app --field-selector=status.phase=Running | grep -q ${SERVICE_NAME}"

# Test 4: Service exists
run_test "Service exists" "kubectl get svc ${SERVICE_NAME} -n ${NAMESPACE}"

# Test 5: HPA exists
run_test "HPA is configured" "kubectl get hpa ${SERVICE_NAME} -n ${NAMESPACE}"

echo ""
echo "=== Endpoint Tests ==="
echo ""

# Get the service endpoint for HTTP tests
SERVICE_IP=$(get_service_endpoint 2>/dev/null || echo "")

if [ -n "${SERVICE_IP}" ]; then
    # Test 6: Health endpoint
    run_test "Health endpoint responds" "kubectl run smoke-test-${RANDOM} --rm -i --restart=Never --image=curlimages/curl -- curl -sf http://${SERVICE_IP}/health --connect-timeout 5"

    # Test 7: Ready endpoint
    run_test "Ready endpoint responds" "kubectl run smoke-test-${RANDOM} --rm -i --restart=Never --image=curlimages/curl -- curl -sf http://${SERVICE_IP}/ready --connect-timeout 5"

    # Test 8: Metrics endpoint
    run_test "Metrics endpoint responds" "kubectl run smoke-test-${RANDOM} --rm -i --restart=Never --image=curlimages/curl -- curl -sf http://${SERVICE_IP}/metrics --connect-timeout 5"
else
    echo -e "${YELLOW}WARNING: Could not get service IP, skipping endpoint tests${NC}"
fi

echo ""
echo "=== Resource Tests ==="
echo ""

# Test 9: Resource limits are set
run_test "Resource limits configured" "kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits}' | grep -q 'cpu'"

# Test 10: Liveness probe configured
run_test "Liveness probe configured" "kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' | grep -q 'httpGet'"

# Test 11: Readiness probe configured
run_test "Readiness probe configured" "kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' | grep -q 'httpGet'"

# Test 12: Security context configured
run_test "Security context configured" "kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.securityContext}' | grep -q 'runAsNonRoot'"

echo ""
echo "============================================"
echo "Smoke Test Results"
echo "============================================"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

# Exit with failure if any tests failed
if [ ${FAILED} -gt 0 ]; then
    echo -e "${RED}Smoke tests FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All smoke tests PASSED${NC}"
    exit 0
fi
