# AI-Powered Threat Intelligence System

A comprehensive n8n workflow-based threat intelligence system that automatically collects, processes, enriches, and analyzes threat indicators using artificial intelligence.

## Features

- **Multi-source Data Collection**: Webhook and email triggers for flexible data ingestion
- **STIX-like Data Normalization**: Standardized threat intelligence format
- **Intelligent Deduplication**: Prevents duplicate processing with confidence updates
- **Multi-source Enrichment**: Integrates with 6 major threat intelligence platforms
- **AI-powered Analysis**: LLM-based threat summarization and prioritization
- **Advanced Threat Scoring**: Algorithmic risk assessment with 0-100 scoring
- **Real-time Alerting**: Slack and email notifications for high-threat indicators
- **Comprehensive Storage**: PostgreSQL database with full audit trail
- **Performance Monitoring**: Rate limiting and execution tracking
- **Visual Dashboards**: Grafana integration for threat visibility

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Data Sources  │───▶│   n8n Workflow   │───▶│   PostgreSQL DB     │
│                 │    │                  │    │                     │
│ • Webhooks      │    │ • Normalization  │    │ • Threat Intel      │
│ • Email IMAP    │    │ • Deduplication  │    │ • Enrichment Data   │
│ • Manual Input  │    │ • Enrichment     │    │ • Alerts History    │
└─────────────────┘    │ • AI Analysis    │    │ • Metrics           │
                       │ • Scoring        │    └─────────────────────┘
                       │ • Alerting       │
                       └──────────────────┘
                                │
                       ┌──────────────────┐
                       │   Threat Intel   │
                       │    Sources       │
                       │                  │
                       │ • OTX            │
                       │ • VirusTotal     │
                       │ • GreyNoise      │
                       │ • Shodan         │
                       │ • AbuseIPDB      │
                       │ • WHOIS/Geo      │
                       └──────────────────┘
```

## Quick Start

### Prerequisites

- n8n instance (self-hosted or cloud)
- PostgreSQL database (v12+)
- Grafana instance (optional, for dashboards)
- API keys for threat intelligence sources
- OpenAI API key for AI analysis
- Slack workspace (for alerts)
- SMTP server (for email alerts)

### 1. Database Setup

1. Create PostgreSQL database:
```bash
createdb threat_intelligence
```

2. Run the schema script:
```bash
psql -d threat_intelligence -f database/schema.sql
```

3. Create database user:
```sql
CREATE USER ti_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE threat_intelligence TO ti_user;
```

### 2. n8n Configuration

1. Import the workflow:
   - Copy the content of `workflows/ai-threat-intelligence-workflow.json`
   - In n8n, go to Workflows → Import from JSON
   - Paste the workflow JSON

2. Configure credentials:
   - Import each credential file from the `credentials/` folder
   - Update API keys and connection details
   - Test each credential connection

### 3. API Keys Setup

#### Required API Keys:

1. **AlienVault OTX**
   - Register at: https://otx.alienvault.com/
   - Navigate to Settings → API Integration
   - Copy your API key

2. **VirusTotal**
   - Register at: https://www.virustotal.com/
   - Go to your profile → API Key
   - Copy your API key

3. **GreyNoise**
   - Register at: https://www.greynoise.io/
   - Visit Account → API Key
   - Copy your API key

4. **Shodan**
   - Register at: https://www.shodan.io/
   - Go to Account → API Key
   - Copy your API key

5. **AbuseIPDB**
   - Register at: https://www.abuseipdb.com/
   - Navigate to API → API Key
   - Copy your API key

6. **OpenAI**
   - Register at: https://platform.openai.com/
   - Go to API Keys → Create new key
   - Copy your API key

### 4. Slack Integration

1. Create a Slack App:
   - Go to https://api.slack.com/apps
   - Click "Create New App" → "From scratch"
   - Name: "Threat Intelligence Bot"

2. Configure Bot permissions:
   - Go to OAuth & Permissions
   - Add scopes: `chat:write`, `channels:read`
   - Install app to workspace
   - Copy Bot User OAuth Token

3. Create/join the #threat-intel channel

### 5. Email Configuration

Configure IMAP and SMTP settings in the credential files:

```json
{
  "name": "Email Credentials",
  "type": "imap",
  "data": {
    "user": "threat-intel@yourcompany.com",
    "password": "your_email_password",
    "host": "imap.yourcompany.com",
    "port": 993,
    "secure": true
  }
}
```

### 6. Activate the Workflow

1. In n8n, open the imported workflow
2. Activate the workflow (toggle switch)
3. Note the webhook URL for external integrations

## Usage

### Data Input Methods

#### 1. Webhook Trigger
Send POST requests to the webhook URL:

```bash
curl -X POST "https://your-n8n-instance/webhook/threat-intel" \
  -H "Content-Type: application/json" \
  -d '{
    "ip_address": "192.168.1.100",
    "source": "firewall_logs",
    "confidence": 80
  }'
```

#### 2. Email Integration
Forward threat intelligence emails to the configured IMAP account. The system will automatically parse IOCs from:
- Email subject and body
- CSV attachments
- JSON attachments

#### 3. Manual Input
Use n8n's manual trigger to input data directly through the interface.

### Supported IOC Types

- **IPv4 Addresses**: `192.168.1.100`
- **IPv6 Addresses**: `2001:0db8:85a3:0000:0000:8a2e:0370:7334`
- **Domain Names**: `malicious-domain.com`
- **URLs**: `https://malicious-site.com/payload`
- **File Hashes**: MD5, SHA1, SHA256
- **Email Addresses**: `attacker@malicious-domain.com`

### Data Processing Flow

1. **Collection**: Data received via webhook or email
2. **Normalization**: Converted to STIX-like format
3. **Deduplication**: Existing IOCs updated, new ones processed
4. **Enrichment**: Queried against 6 threat intelligence sources
5. **AI Analysis**: LLM generates threat summary and recommendations
6. **Scoring**: Algorithmic threat score (0-100) calculated
7. **Storage**: All data stored in PostgreSQL
8. **Alerting**: High-threat IOCs trigger alerts
9. **Dashboard**: Real-time visualization in Grafana

## Threat Scoring Algorithm

The system uses a comprehensive scoring algorithm that considers:

### Base Score (10 points max)
- Original indicator confidence level

### OTX Intelligence (35 points max)
- Pulse count: 5 points per pulse (max 25)
- Malware families: 10 points per family

### VirusTotal (50 points max)
- Malicious URLs: 3 points each (max 30)
- Malicious samples: 2 points each (max 20)

### GreyNoise (40 points max)
- Active scanner: +15 points
- Legitimate service: -10 points
- Malicious classification: +25 points

### Shodan Intelligence (40 points max)
- Suspicious ports: 3 points each
- Vulnerabilities: 8 points each (max 40)

### AbuseIPDB (50 points max)
- Abuse confidence score: 0.3x score
- Report count: 2 points each (max 20)

### Geolocation Risk (15 points max)
- High-risk countries: +10 points
- Proxy/hosting: +5 points

### Threat Levels
- **LOW**: 0-29 points
- **MEDIUM**: 30-49 points
- **HIGH**: 50-69 points
- **CRITICAL**: 70-100 points

## API Rate Limits

The system implements rate limiting for all external APIs:

| Service    | Limit        | Window  |
|------------|--------------|---------|
| OTX        | 1,000 req    | 1 hour  |
| VirusTotal | 4 req        | 1 min   |
| GreyNoise  | 1,000 req    | 1 day   |
| Shodan     | 1 req        | 1 sec   |
| AbuseIPDB  | 1,000 req    | 1 day   |
| OpenAI     | 3 req        | 1 min   |

## Monitoring and Maintenance

### Database Maintenance

The system includes automated maintenance procedures:

1. **Expired IOC Cleanup**: Automatically removes IOCs older than 90 days
2. **Daily Metrics**: Calculates and stores daily statistics
3. **Performance Indexing**: Optimized indexes for query performance

Run manual cleanup:
```sql
SELECT cleanup_expired_iocs();
```

Update daily metrics:
```sql
SELECT update_daily_metrics();
```

### Workflow Monitoring

Monitor workflow health through:
- n8n execution history
- PostgreSQL `workflow_executions` table
- Grafana dashboard alerts
- API rate limit tracking

### Performance Optimization

1. **Database Tuning**:
   - Adjust `shared_buffers` to 25% of RAM
   - Set `effective_cache_size` to 75% of RAM
   - Monitor slow queries with `pg_stat_statements`

2. **n8n Optimization**:
   - Enable workflow execution data saving
   - Configure appropriate timeout values
   - Monitor memory usage

3. **API Optimization**:
   - Implement API key rotation
   - Monitor rate limit usage
   - Cache enrichment results when possible

## Grafana Dashboard

The included Grafana dashboard provides:

### Key Metrics
- Total IOCs processed
- Threat level distribution
- IOC type breakdown
- Processing timeline

### Performance Monitoring
- API response times
- Success rates by source
- Workflow execution status
- Alert activity

### Threat Intelligence Views
- Recent high-threat IOCs
- Top threat sources
- Enrichment performance
- Historical trends

### Setting up the Dashboard

1. Import the dashboard JSON:
   ```bash
   curl -X POST "http://grafana:3000/api/dashboards/db" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_GRAFANA_TOKEN" \
     -d @grafana-dashboard.json
   ```

2. Configure PostgreSQL data source:
   - Host: Your PostgreSQL server
   - Database: `threat_intelligence`
   - User: `ti_user`
   - SSL Mode: Require (recommended)

## Troubleshooting

### Common Issues

1. **Workflow not triggering**:
   - Check webhook URL accessibility
   - Verify credentials are properly configured
   - Ensure workflow is activated

2. **API enrichment failures**:
   - Verify API keys are valid and not expired
   - Check rate limits haven't been exceeded
   - Confirm network connectivity to APIs

3. **Database connection errors**:
   - Verify PostgreSQL credentials
   - Check database server accessibility
   - Confirm schema has been applied

4. **High memory usage**:
   - Reduce batch sizes in workflow
   - Implement data archiving
   - Monitor concurrent executions

### Log Analysis

Check n8n execution logs for:
- Failed API calls
- Rate limit warnings
- Data validation errors
- Performance bottlenecks

Query PostgreSQL logs for:
- Slow queries
- Connection issues
- Lock contention
- Storage space

### Performance Tuning

1. **Workflow Optimization**:
   - Adjust batch sizes based on available resources
   - Implement parallel processing where appropriate
   - Add error handling and retry logic

2. **Database Optimization**:
   - Regularly update table statistics
   - Monitor index usage
   - Implement table partitioning for large datasets

3. **Resource Management**:
   - Monitor CPU and memory usage
   - Scale resources based on processing volume
   - Implement load balancing for high availability

## Security Considerations

### API Key Management
- Store API keys securely using n8n's credential system
- Rotate keys regularly
- Monitor for unauthorized usage
- Implement least-privilege access

### Data Protection
- Encrypt database connections (SSL/TLS)
- Use strong passwords and authentication
- Implement proper access controls
- Regular security updates

### Network Security
- Secure webhook endpoints with authentication
- Use HTTPS for all external communications
- Implement IP whitelisting where possible
- Monitor for anomalous access patterns

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add documentation and tests
5. Submit a pull request

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Review the troubleshooting section
- Check n8n community forums
- Consult vendor documentation for API-specific issues