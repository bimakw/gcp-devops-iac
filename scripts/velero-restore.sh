#!/bin/bash

# Copyright (c) 2024 Bima Kharisma Wicaksana
# Velero Restore Script
# Usage: ./velero-restore.sh <backup-name> [namespace]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat << EOF
Usage: $0 <backup-name> [options]

Restore Kubernetes resources from Velero backup.

OPTIONS:
    -n, --namespace     Restore only specific namespace
    -l, --list          List available backups
    --dry-run           Show what would be restored
    -h, --help          Show this help

EXAMPLES:
    $0 --list                              # List all backups
    $0 daily-full-backup-20240101000000    # Full restore
    $0 daily-full-backup-20240101000000 -n production  # Namespace restore
    $0 daily-full-backup-20240101000000 --dry-run      # Dry run

EOF
    exit 0
}

list_backups() {
    log_info "Available backups:"
    velero backup get
    echo ""
    log_info "Scheduled backups:"
    velero schedule get
}

# Parse arguments
BACKUP_NAME=""
NAMESPACE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace) NAMESPACE="$2"; shift 2 ;;
        -l|--list) list_backups; exit 0 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) BACKUP_NAME="$1"; shift ;;
    esac
done

if [[ -z "${BACKUP_NAME}" ]]; then
    log_error "Backup name required"
    usage
fi

# Check if velero CLI is installed
if ! command -v velero &> /dev/null; then
    log_error "velero CLI not found. Install: brew install velero"
    exit 1
fi

# Check backup exists
log_info "Checking backup: ${BACKUP_NAME}"
if ! velero backup describe "${BACKUP_NAME}" &> /dev/null; then
    log_error "Backup not found: ${BACKUP_NAME}"
    log_info "Use --list to see available backups"
    exit 1
fi

# Show backup details
velero backup describe "${BACKUP_NAME}"
echo ""

# Build restore command
RESTORE_CMD="velero restore create --from-backup ${BACKUP_NAME}"
RESTORE_NAME="restore-${BACKUP_NAME}-$(date +%Y%m%d%H%M%S)"

if [[ -n "${NAMESPACE}" ]]; then
    RESTORE_CMD="${RESTORE_CMD} --include-namespaces ${NAMESPACE}"
    log_info "Restoring namespace: ${NAMESPACE}"
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "DRY RUN - would execute:"
    echo "${RESTORE_CMD} --restore-name ${RESTORE_NAME}"
    exit 0
fi

# Confirm restore
log_warn "This will restore resources from backup: ${BACKUP_NAME}"
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

# Execute restore
log_info "Starting restore..."
${RESTORE_CMD} --restore-name "${RESTORE_NAME}"

# Wait for restore
log_info "Waiting for restore to complete..."
velero restore wait "${RESTORE_NAME}"

# Show results
log_info "Restore completed!"
velero restore describe "${RESTORE_NAME}"
