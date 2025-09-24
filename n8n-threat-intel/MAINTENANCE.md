# Maintenance Guide

This guide covers routine maintenance, troubleshooting, and operational procedures for the n8n AI Threat Intelligence System.

## Table of Contents

1. [Routine Maintenance](#routine-maintenance)
2. [Database Maintenance](#database-maintenance)
3. [Performance Optimization](#performance-optimization)
4. [Troubleshooting](#troubleshooting)
5. [Backup and Recovery](#backup-and-recovery)
6. [Security Updates](#security-updates)
7. [Monitoring and Alerts](#monitoring-and-alerts)

## Routine Maintenance

### Daily Tasks

#### System Health Check
```bash
# Check service status
sudo systemctl status n8n-threat-intel
sudo systemctl status postgresql
sudo systemctl status grafana-server

# Check system resources
df -h
free -m
top -bn1 | head -20

# Check recent logs
journalctl -u n8n-threat-intel --since "1 hour ago"
tail -50 /var/log/postgresql/postgresql.log
```

#### Database Health Check
```sql
-- Connect to database
psql -U threat_intel_app -d threat_intel

-- Check recent threat activity
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as threats,
    COUNT(*) FILTER (WHERE alert_level = 'critical') as critical,
    COUNT(*) FILTER (WHERE alert_level = 'high') as high
FROM threat_intel 
WHERE timestamp >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- Check system health
SELECT * FROM v_system_health;

-- Check for errors
SELECT severity, COUNT(*) 
FROM error_log 
WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
  AND resolved = FALSE
GROUP BY severity;
```

#### API Rate Limit Check
```sql
-- Check current API usage
SELECT 
    service_name,
    requests_made,
    requests_limit,
    ROUND((requests_made::float / requests_limit::float) * 100, 2) as usage_percent,
    reset_time
FROM api_rate_limits 
WHERE reset_time >= NOW()
ORDER BY usage_percent DESC;
```

### Weekly Tasks

#### Performance Review
```sql
-- Analyze workflow execution times
SELECT 
    AVG(EXTRACT(EPOCH FROM (analysis_timestamp - timestamp))/60) as avg_processing_minutes,
    MAX(EXTRACT(EPOCH FROM (analysis_timestamp - timestamp))/60) as max_processing_minutes,
    COUNT(*) as total_processed
FROM threat_intel 
WHERE analysis_timestamp IS NOT NULL
  AND timestamp >= NOW() - INTERVAL '7 days';

-- Check top IOCs by activity
SELECT * FROM v_ioc_intelligence 
ORDER BY hit_count DESC, reputation_score DESC 
LIMIT 20;

-- Review alert effectiveness
SELECT 
    alert_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (delivered_at - sent_at))) as avg_delivery_seconds
FROM alert_history 
WHERE sent_at >= NOW() - INTERVAL '7 days'
GROUP BY alert_type, status;
```

#### Data Cleanup
```sql
-- Run automated cleanup
SELECT cleanup_old_data();

-- Check data retention compliance
SELECT 
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE expires_at < NOW()) as expired_records,
    COUNT(*) FILTER (WHERE expires_at < NOW() + INTERVAL '7 days') as expiring_soon
FROM threat_intel;
```

### Monthly Tasks

#### Index Maintenance
```sql
-- Reindex database
REINDEX DATABASE threat_intel;

-- Update table statistics
ANALYZE;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'threat_intel'
ORDER BY idx_scan DESC;
```

#### Configuration Review
```bash
# Check configuration files for changes
git -C /opt/n8n-threat-intel status

# Review environment variables
grep -v "PASSWORD\|KEY\|SECRET" /opt/n8n-threat-intel/.env

# Check log rotation
logrotate -d /etc/logrotate.d/n8n-threat-intel
```

## Database Maintenance

### Vacuum Operations
```sql
-- Full vacuum (schedule during low activity)
VACUUM FULL threat_intel;

-- Auto vacuum status
SELECT 
    schemaname,
    tablename,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'threat_intel';
```

### Connection Pool Management
```sql
-- Check active connections
SELECT 
    datname,
    usename,
    state,
    COUNT(*)
FROM pg_stat_activity 
WHERE datname = 'threat_intel'
GROUP BY datname, usename, state;

-- Kill idle connections (if needed)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity 
WHERE datname = 'threat_intel'
  AND state = 'idle'
  AND state_change < NOW() - INTERVAL '1 hour';
```

### Storage Management
```sql
-- Check table sizes
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'threat_intel'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check database size
SELECT pg_size_pretty(pg_database_size('threat_intel'));
```

## Performance Optimization

### Query Optimization
```sql
-- Find slow queries
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE query LIKE '%threat_intel%'
ORDER BY mean_time DESC
LIMIT 10;

-- Check query plans for common operations
EXPLAIN ANALYZE 
SELECT * FROM threat_intel 
WHERE alert_level = 'critical' 
  AND timestamp >= NOW() - INTERVAL '24 hours';
```

### Index Optimization
```sql
-- Find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE schemaname = 'threat_intel'
  AND idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find missing indexes
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    seq_tup_read / seq_scan as avg_tup_per_scan
FROM pg_stat_user_tables
WHERE schemaname = 'threat_intel'
  AND seq_scan > 0
ORDER BY seq_tup_read DESC;
```

### System Resource Optimization
```bash
# Check memory usage
ps aux | grep -E "(n8n|postgres)" | awk '{print $4,$11}' | sort -nr

# Check disk I/O
iotop -oa

# Check network connections
netstat -tuln | grep -E "(5678|5432|3000)"

# Optimize PostgreSQL configuration
sudo nano /etc/postgresql/13/main/postgresql.conf

# Key parameters to adjust:
# shared_buffers = 256MB (25% of RAM)
# effective_cache_size = 1GB (75% of RAM)
# work_mem = 4MB
# maintenance_work_mem = 64MB
# max_connections = 100
```

## Troubleshooting

### Common Issues and Solutions

#### Workflow Not Executing
**Symptoms**: New threats not being processed
```bash
# Check n8n service
sudo systemctl status n8n-threat-intel
sudo journalctl -u n8n-threat-intel -f

# Check webhook accessibility
curl -I http://localhost:5678/webhook/threat-intel-webhook

# Test database connectivity
psql -U threat_intel_app -d threat_intel -c "SELECT 1;"

# Check credentials in n8n
# Access n8n UI and verify all credentials are valid
```

#### High Memory Usage
**Symptoms**: System running slowly, out of memory errors
```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head -10

# Restart services if needed
sudo systemctl restart n8n-threat-intel
sudo systemctl restart postgresql

# Optimize PostgreSQL
sudo nano /etc/postgresql/13/main/postgresql.conf
# Reduce shared_buffers if too high
```

#### Database Connection Issues
**Symptoms**: Connection timeout errors
```sql
-- Check connection limits
SHOW max_connections;
SELECT COUNT(*) FROM pg_stat_activity;

-- Check long-running queries
SELECT 
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query 
FROM pg_stat_activity 
WHERE state = 'active'
  AND now() - pg_stat_activity.query_start > interval '5 minutes';

-- Kill problematic queries
SELECT pg_cancel_backend(PID);
```

#### API Rate Limit Exceeded
**Symptoms**: External API errors, delayed processing
```sql
-- Check current usage
SELECT * FROM api_rate_limits;

-- Reset counters if needed (use carefully)
UPDATE api_rate_limits 
SET requests_made = 0, reset_time = NOW() + INTERVAL '1 day'
WHERE service_name = 'virustotal';
```

#### High False Positive Rate
**Symptoms**: Too many low-value alerts
```sql
-- Analyze threat score distribution
SELECT 
    CASE 
        WHEN threat_score >= 80 THEN 'Critical (80+)'
        WHEN threat_score >= 60 THEN 'High (60-79)'
        WHEN threat_score >= 40 THEN 'Medium (40-59)'
        WHEN threat_score >= 20 THEN 'Low (20-39)'
        ELSE 'Info (0-19)'
    END as score_range,
    COUNT(*) as count,
    ROUND(AVG(threat_score), 2) as avg_score
FROM threat_intel 
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY 
    CASE 
        WHEN threat_score >= 80 THEN 'Critical (80+)'
        WHEN threat_score >= 60 THEN 'High (60-79)'
        WHEN threat_score >= 40 THEN 'Medium (40-59)'
        WHEN threat_score >= 20 THEN 'Low (20-39)'
        ELSE 'Info (0-19)'
    END
ORDER BY avg_score DESC;

-- Review sources generating high false positives
SELECT 
    source,
    COUNT(*) as total_threats,
    AVG(threat_score) as avg_score,
    COUNT(*) FILTER (WHERE alert_level IN ('critical', 'high')) as high_priority
FROM threat_intel 
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY source
ORDER BY avg_score ASC;
```

### Log Analysis
```bash
# Check n8n logs for errors
journalctl -u n8n-threat-intel | grep -i error

# Check PostgreSQL logs
tail -100 /var/log/postgresql/postgresql.log | grep -i error

# Check system logs
dmesg | tail -20
```

## Backup and Recovery

### Database Backup
```bash
#!/bin/bash
# Database backup script

BACKUP_DIR="/opt/backups/threat-intel"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/threat_intel_backup_$DATE.sql"

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform backup
pg_dump -U threat_intel_app -d threat_intel -f $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
```

### Configuration Backup
```bash
#!/bin/bash
# Configuration backup script

CONFIG_DIR="/opt/n8n-threat-intel"
BACKUP_DIR="/opt/backups/config"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup configuration files
tar -czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" \
    -C $CONFIG_DIR \
    --exclude=".env" \
    --exclude="node_modules" \
    --exclude="logs" \
    .

echo "Configuration backup completed: $BACKUP_DIR/config_backup_$DATE.tar.gz"
```

### Recovery Procedures
```bash
# Database recovery
psql -U threat_intel_app -d threat_intel < backup_file.sql

# Service recovery
sudo systemctl stop n8n-threat-intel
sudo systemctl start n8n-threat-intel

# Configuration recovery
tar -xzf config_backup.tar.gz -C /opt/n8n-threat-intel/
sudo systemctl restart n8n-threat-intel
```

## Security Updates

### System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js and n8n
npm update -g n8n

# Update PostgreSQL
sudo apt install postgresql postgresql-contrib
```

### Security Hardening
```bash
# Check for security vulnerabilities
npm audit

# Update SSL certificates
sudo certbot renew

# Review user permissions
sudo -u postgres psql -c "\\du"

# Check file permissions
ls -la /opt/n8n-threat-intel/
```

### API Key Rotation
```bash
# Update API keys in environment file
sudo nano /opt/n8n-threat-intel/.env

# Update credentials in n8n UI
# Restart service to apply changes
sudo systemctl restart n8n-threat-intel
```

## Monitoring and Alerts

### Set Up Monitoring Alerts
```bash
# Create monitoring script
cat > /opt/n8n-threat-intel/monitor.sh << 'EOF'
#!/bin/bash

# Check critical thresholds
CRITICAL_THREATS=$(psql -U threat_intel_readonly -d threat_intel -t -c "SELECT COUNT(*) FROM threat_intel WHERE alert_level = 'critical' AND timestamp >= NOW() - INTERVAL '1 hour'")
ERROR_COUNT=$(psql -U threat_intel_readonly -d threat_intel -t -c "SELECT COUNT(*) FROM error_log WHERE created_at >= NOW() - INTERVAL '1 hour' AND resolved = false")

# Send alerts if thresholds exceeded
if [ $CRITICAL_THREATS -gt 5 ]; then
    echo "ALERT: $CRITICAL_THREATS critical threats in last hour" | mail -s "High Critical Threat Volume" admin@company.com
fi

if [ $ERROR_COUNT -gt 10 ]; then
    echo "ALERT: $ERROR_COUNT unresolved errors in last hour" | mail -s "High Error Rate" admin@company.com
fi
EOF

# Add to crontab
echo "0 * * * * /opt/n8n-threat-intel/monitor.sh" | crontab -
```

### Grafana Alerts
Configure alerts in Grafana for:
- High threat volume
- System errors
- API rate limits
- Database performance
- Service availability

For additional support, refer to the main [README.md](README.md) and [INSTALL.md](INSTALL.md) files.