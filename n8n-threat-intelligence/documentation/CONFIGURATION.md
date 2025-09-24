# Configuration Guide

## Overview

This document provides detailed configuration options for the AI-Powered Threat Intelligence System. All configurations are managed through n8n's interface and PostgreSQL database settings.

## n8n Workflow Configuration

### Webhook Configuration

The webhook trigger accepts threat intelligence data in multiple formats:

#### Basic IOC Submission
```json
{
  "ip_address": "192.168.1.100",
  "source": "firewall_logs",
  "confidence": 80
}
```

#### Advanced IOC Submission
```json
{
  "indicators": [
    {
      "type": "ipv4-addr",
      "value": "192.168.1.100",
      "confidence": 85,
      "labels": ["malicious-activity"],
      "source": "honeypot_logs",
      "context": {
        "first_seen": "2024-01-01T10:00:00Z",
        "threat_type": "botnet",
        "campaign": "apt29"
      }
    }
  ]
}
```

#### Batch Submission
```json
{
  "batch": true,
  "source": "threat_feed",
  "indicators": [
    {"type": "domain", "value": "malicious-domain.com"},
    {"type": "hash", "value": "abc123..."},
    {"type": "url", "value": "https://malicious-site.com/payload"}
  ]
}
```

### Email Trigger Configuration

Configure the email trigger to process different email formats:

#### IMAP Settings
```json
{
  "server": "imap.company.com",
  "port": 993,
  "secure": true,
  "folder": "INBOX",
  "markSeen": true,
  "downloadAttachments": true,
  "maxAttachmentSize": 10485760
}
```

#### Email Parsing Rules
The system automatically extracts IOCs from:
- Email subject lines
- Email body text
- CSV attachments (IP, Domain, Hash columns)
- JSON attachments (structured IOC data)

### Data Normalization Settings

#### STIX Format Configuration
Modify the normalization node to customize STIX object creation:

```javascript
// Custom IOC type mapping
const IOC_TYPE_MAPPING = {
  'ip': 'ipv4-addr',
  'domain': 'domain-name',
  'hash': 'file',
  'url': 'url'
};

// Custom confidence mapping
const CONFIDENCE_MAPPING = {
  'high': 90,
  'medium': 70,
  'low': 40
};
```

### Deduplication Configuration

#### Time-based Deduplication
```javascript
// Configure deduplication time window (hours)
const DEDUP_WINDOW_HOURS = 24;

// Custom deduplication key generation
function generateDedupKey(ioc) {
  return `${ioc.type}_${ioc.value}_${ioc.source}`;
}
```

### Enrichment Configuration

#### API Timeout Settings
```javascript
// API timeout configuration (milliseconds)
const API_TIMEOUTS = {
  otx: 30000,
  virustotal: 45000,
  greynoise: 30000,
  shodan: 60000,
  abuseipdb: 30000,
  openai: 120000
};
```

#### Retry Configuration
```javascript
// Retry settings for failed API calls
const RETRY_CONFIG = {
  maxAttempts: 3,
  backoffMs: 1000,
  exponentialBackoff: true
};
```

### Rate Limiting Configuration

#### Custom Rate Limits
Modify rate limits based on your API subscriptions:

```javascript
const RATE_LIMITS = {
  otx: { requests: 2000, window: 3600 },      // Premium: 2000/hour
  virustotal: { requests: 1000, window: 60 },  // Premium: 1000/minute
  greynoise: { requests: 10000, window: 86400 }, // Enterprise: 10k/day
  shodan: { requests: 100, window: 60 },        // Premium: 100/minute
  abuseipdb: { requests: 5000, window: 86400 }, // Premium: 5k/day
  openai: { requests: 60, window: 60 }          // Pay-per-use
};
```

### Threat Scoring Configuration

#### Scoring Weights
Customize the threat scoring algorithm:

```javascript
const SCORING_WEIGHTS = {
  otx: {
    pulseCount: 5,        // Points per pulse
    maxPulseScore: 25,    // Maximum pulse score
    malwareFamilyScore: 10 // Points per malware family
  },
  virustotal: {
    maliciousUrlScore: 3,     // Points per malicious URL
    maliciousSampleScore: 2,  // Points per malicious sample
    maxUrlScore: 30,
    maxSampleScore: 20
  },
  greynoise: {
    noiseScore: 15,           // Internet scanner score
    riotPenalty: -10,         // Legitimate service penalty
    maliciousScore: 25        // Malicious classification
  },
  shodan: {
    suspiciousPortScore: 3,   // Points per suspicious port
    vulnerabilityScore: 8,    // Points per vulnerability
    maxVulnScore: 40
  },
  abuseipdb: {
    confidenceMultiplier: 0.3, // Multiplier for abuse confidence
    reportScore: 2,            // Points per report
    maxReportScore: 20
  },
  geolocation: {
    highRiskCountryScore: 10,  // High-risk country bonus
    proxyHostingScore: 5       // Proxy/hosting penalty
  }
};
```

#### Threat Level Thresholds
```javascript
const THREAT_THRESHOLDS = {
  low: { min: 0, max: 29 },
  medium: { min: 30, max: 49 },
  high: { min: 50, max: 69 },
  critical: { min: 70, max: 100 }
};
```

### AI Summarization Configuration

#### OpenAI Model Settings
```javascript
const AI_CONFIG = {
  model: "gpt-3.5-turbo",
  temperature: 0.3,
  maxTokens: 1000,
  systemPrompt: `You are a cybersecurity threat intelligence analyst. 
    Analyze the provided threat data and create a comprehensive threat 
    assessment summary. Focus on actionability, context, and risk 
    prioritization.`
};
```

#### Custom AI Prompts
```javascript
const CUSTOM_PROMPTS = {
  ip_analysis: `Analyze this IP address threat intelligence data...`,
  domain_analysis: `Analyze this domain threat intelligence data...`,
  hash_analysis: `Analyze this file hash threat intelligence data...`,
  url_analysis: `Analyze this URL threat intelligence data...`
};
```

### Alerting Configuration

#### Alert Thresholds
```javascript
const ALERT_CONFIG = {
  minimumThreatScore: 50,    // Minimum score for alerts
  criticalScore: 70,         // Score for critical alerts
  alertChannels: {
    slack: {
      enabled: true,
      channel: "#threat-intel",
      mentionUsers: ["@security-team"],
      criticalChannel: "#security-alerts"
    },
    email: {
      enabled: true,
      recipients: ["security-team@company.com"],
      criticalRecipients: ["ciso@company.com", "soc-manager@company.com"]
    }
  }
};
```

#### Custom Alert Templates

**Slack Alert Template:**
```javascript
const SLACK_ALERT_TEMPLATE = `
🚨 **{{THREAT_LEVEL}} THREAT DETECTED** 🚨

**IOC:** \`{{IOC_VALUE}}\`
**Type:** {{IOC_TYPE}}
**Score:** {{THREAT_SCORE}}/100
**Source:** {{SOURCE}}
**Confidence:** {{CONFIDENCE}}%

**Risk Factors:**
{{#each RISK_FACTORS}}
• {{this}}
{{/each}}

**AI Analysis:**
\`\`\`
{{AI_SUMMARY}}
\`\`\`

*Detection Time:* {{TIMESTAMP}}
*Workflow:* {{WORKFLOW_URL}}
`;
```

**Email Alert Template:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Threat Intelligence Alert</title>
</head>
<body>
    <h1>{{THREAT_LEVEL}} Threat Detected</h1>
    
    <table border="1" cellpadding="5">
        <tr><td><strong>IOC</strong></td><td>{{IOC_VALUE}}</td></tr>
        <tr><td><strong>Type</strong></td><td>{{IOC_TYPE}}</td></tr>
        <tr><td><strong>Threat Score</strong></td><td>{{THREAT_SCORE}}/100</td></tr>
        <tr><td><strong>Threat Level</strong></td><td>{{THREAT_LEVEL}}</td></tr>
        <tr><td><strong>Source</strong></td><td>{{SOURCE}}</td></tr>
        <tr><td><strong>Confidence</strong></td><td>{{CONFIDENCE}}%</td></tr>
    </table>
    
    <h3>Risk Factors:</h3>
    <ul>
        {{#each RISK_FACTORS}}
        <li>{{this}}</li>
        {{/each}}
    </ul>
    
    <h3>AI Analysis:</h3>
    <pre>{{AI_SUMMARY}}</pre>
    
    <p><small>Generated at: {{TIMESTAMP}}</small></p>
</body>
</html>
```

## Database Configuration

### Connection Settings

#### PostgreSQL Connection Pool
```sql
-- Recommended connection pool settings
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '8MB';
ALTER SYSTEM SET maintenance_work_mem = '128MB';
```

#### Performance Tuning
```sql
-- Query optimization settings
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- WAL settings
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET checkpoint_timeout = '10min';
```

### Data Retention Configuration

#### Automatic Cleanup Settings
```sql
-- Configure retention periods
UPDATE pg_settings 
SET setting = '90' 
WHERE name = 'default_retention_days';

-- Create cleanup job (run daily)
SELECT cron.schedule('cleanup-expired-iocs', '0 2 * * *', 'SELECT cleanup_expired_iocs();');
```

#### Manual Retention Rules
```sql
-- Delete IOCs older than specified days
CREATE OR REPLACE FUNCTION cleanup_by_age(retention_days INTEGER)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM threat_intelligence 
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '1 day' * retention_days)
    AND is_false_positive = FALSE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;
```

### Index Configuration

#### Custom Indexes
```sql
-- Performance indexes for common queries
CREATE INDEX CONCURRENTLY idx_ti_composite_search 
ON threat_intelligence (ioc_type, threat_level, created_at DESC);

CREATE INDEX CONCURRENTLY idx_ti_json_source 
ON threat_intelligence USING GIN ((enrichment_data->'source'));

CREATE INDEX CONCURRENTLY idx_ti_score_range 
ON threat_intelligence (threat_score) 
WHERE threat_score >= 50;
```

### Partitioning Configuration

#### Time-based Partitioning
```sql
-- Enable partitioning for large datasets
CREATE TABLE threat_intelligence_partitioned (
    LIKE threat_intelligence INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE threat_intelligence_2024_01 
PARTITION OF threat_intelligence_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE threat_intelligence_2024_02 
PARTITION OF threat_intelligence_partitioned
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

## Environment Configuration

### Development Environment
```env
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=dev_password
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

# Database Configuration
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=threat_intelligence_dev
DB_POSTGRESDB_USER=ti_user
DB_POSTGRESDB_PASSWORD=dev_password

# API Configuration
RATE_LIMIT_ENABLED=false
LOG_LEVEL=debug
```

### Production Environment
```env
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_production_password
N8N_HOST=ti.company.com
N8N_PORT=443
N8N_PROTOCOL=https
N8N_SSL_KEY=/path/to/ssl.key
N8N_SSL_CERT=/path/to/ssl.cert

# Database Configuration
DB_POSTGRESDB_HOST=db.company.com
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=threat_intelligence
DB_POSTGRESDB_USER=ti_user
DB_POSTGRESDB_PASSWORD=secure_production_password
DB_POSTGRESDB_SSL=true

# Security Configuration
WEBHOOK_SECRET=your_webhook_secret
API_RATE_LIMIT_ENABLED=true
LOG_LEVEL=info
EXECUTION_DATA_SAVE_ON_ERROR=all
EXECUTION_DATA_SAVE_ON_SUCCESS=none
```

## Monitoring Configuration

### Health Check Endpoints

Create custom health check queries:
```sql
-- System health check
CREATE OR REPLACE FUNCTION health_check()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'database_status', 'healthy',
        'total_iocs', (SELECT COUNT(*) FROM threat_intelligence),
        'recent_iocs', (SELECT COUNT(*) FROM threat_intelligence WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour'),
        'failed_enrichments', (SELECT COUNT(*) FROM enrichment_sources WHERE is_successful = FALSE AND retrieved_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour'),
        'timestamp', CURRENT_TIMESTAMP
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### Alert Configuration

#### Database Alerts
```sql
-- Monitor for high error rates
CREATE OR REPLACE FUNCTION check_error_rate()
RETURNS BOOLEAN AS $$
DECLARE
    error_rate NUMERIC;
BEGIN
    SELECT (COUNT(CASE WHEN is_successful = FALSE THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC * 100)
    INTO error_rate
    FROM enrichment_sources
    WHERE retrieved_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour';
    
    RETURN error_rate > 20; -- Alert if error rate > 20%
END;
$$ LANGUAGE plpgsql;
```

### Log Configuration

#### n8n Logging
```json
{
  "logging": {
    "level": "info",
    "outputs": [
      {
        "type": "console"
      },
      {
        "type": "file",
        "file": "/var/log/n8n/workflow.log",
        "maxFiles": 7,
        "maxSize": "10m"
      }
    ]
  }
}
```

#### PostgreSQL Logging
```postgresql.conf
# Logging configuration
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000  # Log slow queries > 1 second
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
```

This configuration guide provides comprehensive settings for all aspects of the AI-Powered Threat Intelligence System. Adjust these settings based on your specific requirements, environment constraints, and organizational policies.