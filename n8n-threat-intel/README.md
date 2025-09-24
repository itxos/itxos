# n8n AI Threat Intelligence System

A comprehensive threat intelligence automation system built with n8n that processes IOCs (Indicators of Compromise), performs AI-powered analysis, and provides real-time alerting.

## Features

- **Multi-source ingestion**: Webhook and email triggers for threat data
- **Intelligent processing**: AI-powered threat analysis using OpenAI GPT-4
- **External enrichment**: Integration with VirusTotal, AbuseIPDB, and other threat intelligence services
- **Deduplication**: Automatic detection and handling of duplicate threats
- **Smart alerting**: Configurable alerting based on threat severity and score
- **Comprehensive storage**: PostgreSQL database with optimized schema
- **Real-time monitoring**: Grafana dashboards for threat visualization
- **Error handling**: Robust error handling and retry mechanisms
- **Rate limiting**: Built-in API rate limiting to prevent quota exhaustion

## System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌───────────────────┐
│   Data Sources  │    │   n8n Workflow   │    │   External APIs   │
│                 │    │                  │    │                   │
│  • Webhooks     │───▶│  • Data Norm.    │───▶│  • VirusTotal     │
│  • Email        │    │  • Deduplication │    │  • AbuseIPDB      │
│  • Manual       │    │  • AI Analysis   │    │  • OpenAI         │
└─────────────────┘    │  • Enrichment    │    └───────────────────┘
                       └──────────┬───────┘
                                  │
                                  ▼
┌─────────────────┐    ┌──────────────────┐    ┌───────────────────┐
│   PostgreSQL    │◀───│   Processing     │───▶│   Alert Channels  │
│   Database      │    │   Engine         │    │                   │
│                 │    │                  │    │  • Slack          │
│  • Threats      │    │  • Scoring       │    │  • Email          │
│  • IOCs         │    │  • Classification│    │  • Webhooks       │
│  • Analytics    │    │  • Recommendations│   └───────────────────┘
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐
│   Grafana       │
│   Dashboard     │
│                 │
│  • Threat View  │
│  • Analytics    │
│  • Monitoring   │
└─────────────────┘
```

## Quick Start

### Prerequisites

- n8n (version 1.0+)
- PostgreSQL (version 12+)
- Grafana (version 8.0+)
- API keys for external services

### 1. Database Setup

```bash
# Create database
psql -U postgres -c "CREATE DATABASE threat_intel;"

# Run schema creation
psql -U postgres -d threat_intel -f schema.sql
```

### 2. Configure Environment Variables

Create a `.env` file with the following variables:

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=threat_intel
DB_USERNAME=threat_intel_app
DB_PASSWORD=your_secure_password

# API Keys
OPENAI_API_KEY=your_openai_api_key
VIRUSTOTAL_API_KEY=your_virustotal_api_key
ABUSEIPDB_API_KEY=your_abuseipdb_api_key

# Communication
SLACK_BOT_TOKEN=your_slack_bot_token
SMTP_HOST=your_smtp_host
SMTP_USER=your_smtp_user
SMTP_PASSWORD=your_smtp_password
SECURITY_TEAM_EMAIL=security-team@company.com

# IMAP for email ingestion
IMAP_HOST=your_imap_host
IMAP_USER=your_imap_user
IMAP_PASSWORD=your_imap_password
```

### 3. Import n8n Workflow

1. Open n8n web interface
2. Go to **Workflows** → **Import from file**
3. Select `workflow.json`
4. Configure credentials for each service:
   - PostgreSQL connection
   - OpenAI API
   - VirusTotal API
   - AbuseIPDB API
   - Slack Bot
   - Email (SMTP & IMAP)

### 4. Setup Grafana Dashboard

1. Add PostgreSQL datasource in Grafana
2. Import dashboard from `dashboard.json`
3. Configure datasource connections

## Usage

### Webhook Integration

Send threat intelligence data to the webhook endpoint:

```bash
curl -X POST https://your-n8n-instance.com/webhook/threat-intel-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "source": "security_team",
    "severity": "high",
    "confidence": 85,
    "tlp": "AMBER",
    "ips": ["192.168.1.100", "10.0.0.50"],
    "domains": ["malicious-domain.com"],
    "hashes": ["a1b2c3d4e5f6..."],
    "description": "Suspected C2 infrastructure"
  }'
```

### Email Integration

Forward threat intelligence emails to the configured IMAP mailbox. The system automatically:
- Parses email content
- Extracts IOCs using regex patterns
- Normalizes data format
- Processes through the workflow

### Manual Processing

Use the n8n interface to manually trigger workflows with custom threat data.

## Configuration

### Threat Scoring

The system calculates composite threat scores based on:
- **VirusTotal detections** (40% weight)
- **AbuseIPDB confidence** (30% weight)  
- **AI analysis severity** (30% weight)

Score ranges:
- **90-100**: Critical (immediate response)
- **70-89**: High (enhanced monitoring)
- **40-69**: Medium (standard monitoring)
- **20-39**: Low (log and track)
- **0-19**: Info (minimal action)

### Alert Thresholds

Configure alerting thresholds in `config.json`:

```json
{
  "alerting": {
    "thresholds": {
      "critical": {
        "threat_score_min": 80,
        "immediate_notification": true,
        "escalation_minutes": 15
      }
    }
  }
}
```

### Rate Limiting

API rate limits are automatically managed:
- **VirusTotal**: 4 requests/minute (free tier)
- **AbuseIPDB**: 1000 requests/day
- **OpenAI**: 60 requests/minute

## Monitoring

### Key Metrics

Monitor these metrics in Grafana:
- Threat volume and trends
- Processing times
- Alert response times
- API rate limit usage
- Error rates
- System health

### Health Checks

The system includes automated health checks for:
- Database connectivity
- External API availability
- Workflow execution status
- Alert delivery success

## Maintenance

### Regular Tasks

1. **Database cleanup** (weekly):
   ```sql
   SELECT cleanup_old_data();
   ```

2. **Index maintenance** (monthly):
   ```sql
   REINDEX DATABASE threat_intel;
   ```

3. **Backup verification** (daily):
   - Verify automated backups
   - Test restore procedures

### Troubleshooting

#### Common Issues

**Workflow not triggering**:
- Check webhook URL configuration
- Verify IMAP credentials
- Review n8n execution logs

**High false positive rate**:
- Adjust threat scoring weights
- Update IOC extraction patterns
- Review AI analysis prompts

**API quota exceeded**:
- Monitor rate limiting dashboard
- Implement request queuing
- Consider upgrading API plans

**Database performance**:
- Monitor query execution times
- Review index usage
- Consider data archival

### Logs

Access logs through:
- n8n execution history
- PostgreSQL logs
- System metrics table
- Error log table

## Security Considerations

### Data Privacy
- All threat data follows TLP (Traffic Light Protocol) guidelines
- PII detection and masking
- Encrypted storage and transmission

### Access Control
- Role-based database permissions
- API key rotation
- Network access restrictions

### Compliance
- Data retention policies
- Audit logging
- SOC 2 Type II considerations

## API Reference

### Webhook Endpoints

**POST** `/webhook/threat-intel-webhook`
- Accepts JSON threat intelligence data
- Returns processing status and threat ID

### Database Views

- `v_active_threats`: Current high-priority threats
- `v_ioc_intelligence`: IOC reputation and statistics  
- `v_daily_threat_summary`: Daily threat metrics
- `v_system_health`: System performance metrics

## Contributing

### Development Setup

1. Clone the repository
2. Set up development environment
3. Configure test database
4. Run test suite

### Adding New IOC Types

1. Update data normalization function
2. Extend database schema
3. Update Grafana dashboards
4. Add extraction patterns

### Integrating New APIs

1. Add API configuration to `config.json`
2. Create new n8n node
3. Update aggregation logic
4. Add rate limiting

## Support

For issues and questions:
- Check troubleshooting guide
- Review n8n documentation
- Contact security team

## License

This project is licensed under the MIT License - see the LICENSE file for details.