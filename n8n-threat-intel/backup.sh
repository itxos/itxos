#!/bin/bash

# n8n AI Threat Intelligence System - Backup Script
# This script performs automated backups of the database and configuration files

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/threat-intel}"
DB_NAME="${DB_NAME:-threat_intel}"
DB_USER="${DB_USERNAME:-threat_intel_app}"
CONFIG_DIR="${CONFIG_DIR:-/opt/n8n-threat-intel}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
S3_ENABLED="${BACKUP_S3_ENABLED:-false}"
S3_BUCKET="${BACKUP_S3_BUCKET:-}"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$BACKUP_DIR/backup.log"
}

# Database backup function
backup_database() {
    log "Starting database backup..."
    
    local backup_file="$BACKUP_DIR/threat_intel_db_$TIMESTAMP.sql"
    
    # Perform database dump
    if pg_dump -U "$DB_USER" -d "$DB_NAME" -f "$backup_file"; then
        # Compress the backup
        gzip "$backup_file"
        log "Database backup completed: ${backup_file}.gz"
        echo "${backup_file}.gz"
    else
        log "ERROR: Database backup failed"
        exit 1
    fi
}

# Configuration backup function
backup_config() {
    log "Starting configuration backup..."
    
    local backup_file="$BACKUP_DIR/threat_intel_config_$TIMESTAMP.tar.gz"
    
    # Create configuration backup (excluding sensitive files)
    if tar -czf "$backup_file" \
        -C "$CONFIG_DIR" \
        --exclude=".env" \
        --exclude="node_modules" \
        --exclude="logs" \
        --exclude="*.log" \
        .; then
        log "Configuration backup completed: $backup_file"
        echo "$backup_file"
    else
        log "ERROR: Configuration backup failed"
        exit 1
    fi
}

# S3 upload function
upload_to_s3() {
    local file="$1"
    local s3_path="s3://$S3_BUCKET/threat-intel-backups/$(basename "$file")"
    
    if command -v aws >/dev/null 2>&1; then
        if aws s3 cp "$file" "$s3_path"; then
            log "Uploaded to S3: $s3_path"
        else
            log "WARNING: S3 upload failed for $file"
        fi
    else
        log "WARNING: AWS CLI not found, skipping S3 upload"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    # Local cleanup
    find "$BACKUP_DIR" -name "threat_intel_*.gz" -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "threat_intel_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # S3 cleanup (if enabled and AWS CLI available)
    if [ "$S3_ENABLED" = "true" ] && command -v aws >/dev/null 2>&1; then
        local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
        aws s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "threat-intel-backups/" \
            --query "Contents[?LastModified<'$cutoff_date'].Key" --output text | \
        while read -r key; do
            if [ -n "$key" ]; then
                aws s3 rm "s3://$S3_BUCKET/$key"
                log "Deleted from S3: s3://$S3_BUCKET/$key"
            fi
        done
    fi
    
    log "Cleanup completed"
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    if [ "${backup_file##*.}" = "gz" ]; then
        # Test gzip integrity
        if gzip -t "$backup_file"; then
            log "Backup integrity verified: $backup_file"
            return 0
        else
            log "ERROR: Backup integrity check failed: $backup_file"
            return 1
        fi
    fi
    
    return 0
}

# Send notification
send_notification() {
    local status="$1"
    local message="$2"
    
    # Send email notification if configured
    if command -v mail >/dev/null 2>&1 && [ -n "${NOTIFICATION_EMAIL:-}" ]; then
        echo "$message" | mail -s "Threat Intel Backup: $status" "$NOTIFICATION_EMAIL"
    fi
    
    # Send Slack notification if configured
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Threat Intel Backup: $status\\n$message\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi
}

# Main execution
main() {
    log "Starting backup process..."
    
    local db_backup=""
    local config_backup=""
    local success=true
    
    # Perform backups
    if db_backup=$(backup_database); then
        if verify_backup "$db_backup"; then
            if [ "$S3_ENABLED" = "true" ]; then
                upload_to_s3 "$db_backup"
            fi
        else
            success=false
        fi
    else
        success=false
    fi
    
    if config_backup=$(backup_config); then
        if verify_backup "$config_backup"; then
            if [ "$S3_ENABLED" = "true" ]; then
                upload_to_s3 "$config_backup"
            fi
        else
            success=false
        fi
    else
        success=false
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Calculate backup sizes
    local total_size=0
    if [ -f "$db_backup" ]; then
        total_size=$((total_size + $(stat -f%z "$db_backup" 2>/dev/null || stat -c%s "$db_backup" 2>/dev/null || echo 0)))
    fi
    if [ -f "$config_backup" ]; then
        total_size=$((total_size + $(stat -f%z "$config_backup" 2>/dev/null || stat -c%s "$config_backup" 2>/dev/null || echo 0)))
    fi
    
    # Send notification
    if [ "$success" = true ]; then
        local message="Backup completed successfully at $TIMESTAMP
Database backup: $(basename "$db_backup")
Config backup: $(basename "$config_backup")
Total size: $(numfmt --to=iec "$total_size")
Location: $BACKUP_DIR"
        
        log "Backup process completed successfully"
        send_notification "SUCCESS" "$message"
    else
        local message="Backup process encountered errors at $TIMESTAMP
Check backup logs at $BACKUP_DIR/backup.log"
        
        log "Backup process completed with errors"
        send_notification "FAILED" "$message"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --database-only)
        backup_database
        ;;
    --config-only)
        backup_config
        ;;
    --cleanup-only)
        cleanup_old_backups
        ;;
    --help)
        cat << EOF
Usage: $0 [OPTIONS]

Options:
    --database-only   Backup database only
    --config-only     Backup configuration only
    --cleanup-only    Clean up old backups only
    --help           Show this help message

Environment variables:
    BACKUP_DIR                 Backup directory (default: /opt/backups/threat-intel)
    BACKUP_RETENTION_DAYS      Days to keep backups (default: 30)
    BACKUP_S3_ENABLED          Enable S3 upload (default: false)
    BACKUP_S3_BUCKET           S3 bucket name
    NOTIFICATION_EMAIL         Email for notifications
    SLACK_WEBHOOK_URL          Slack webhook for notifications

EOF
        ;;
    *)
        main "$@"
        ;;
esac