# Installation and Setup Guide

## Prerequisites

Before installing the AI-Powered Threat Intelligence System, ensure you have:

- n8n instance (v1.0+) - self-hosted or cloud
- PostgreSQL database (v12+) with 10GB+ storage
- 4GB+ RAM for processing
- Internet connectivity for API calls
- Valid SSL certificates (for production)

## Step-by-Step Installation

### 1. Environment Preparation

#### n8n Installation (Self-hosted)
```bash
# Using Docker Compose
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_secure_password
      - N8N_HOST=your-domain.com
      - N8N_PROTOCOL=https
      - N8N_PORT=443
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    restart: always
    environment:
      - POSTGRES_DB=threat_intelligence
      - POSTGRES_USER=ti_user
      - POSTGRES_PASSWORD=your_secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  n8n_data:
  postgres_data:
```

#### PostgreSQL Setup
```bash
# Connect to PostgreSQL
psql -h localhost -U postgres

# Create database and user
CREATE DATABASE threat_intelligence;
CREATE USER ti_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE threat_intelligence TO ti_user;

# Exit and apply schema
\q
psql -h localhost -U ti_user -d threat_intelligence -f database/schema.sql
```

### 2. API Keys Acquisition

#### AlienVault OTX
1. Visit https://otx.alienvault.com/
2. Create account or login
3. Navigate to Settings → API Integration
4. Copy API Key
5. Test: `curl -H "X-OTX-API-KEY: YOUR_KEY" https://otx.alienvault.com/api/v1/user/me`

#### VirusTotal
1. Visit https://www.virustotal.com/
2. Create account or login
3. Go to your profile (top right) → API Key
4. Copy API Key
5. Test: `curl -H "x-apikey: YOUR_KEY" https://www.virustotal.com/vtapi/v2/ip-address/report?ip=8.8.8.8`

#### GreyNoise
1. Visit https://www.greynoise.io/
2. Sign up for Community or Enterprise account
3. Navigate to Account → API Key
4. Copy API Key
5. Test: `curl -H "key: YOUR_KEY" https://api.greynoise.io/v3/community/8.8.8.8`

#### Shodan
1. Visit https://www.shodan.io/
2. Create account
3. Go to Account Overview → API Key
4. Copy API Key
5. Test: `curl "https://api.shodan.io/shodan/host/8.8.8.8?key=YOUR_KEY"`

#### AbuseIPDB
1. Visit https://www.abuseipdb.com/
2. Register account
3. Navigate to API → Create Key
4. Copy API Key
5. Test: `curl -H "Key: YOUR_KEY" "https://api.abuseipdb.com/api/v2/check?ipAddress=8.8.8.8"`

#### OpenAI
1. Visit https://platform.openai.com/
2. Create account and add billing method
3. Go to API Keys → Create new secret key
4. Copy API Key
5. Test: `curl -H "Authorization: Bearer YOUR_KEY" https://api.openai.com/v1/models`

### 3. n8n Workflow Import

1. Access your n8n instance
2. Go to Workflows → Import from JSON
3. Paste the content of `workflows/ai-threat-intelligence-workflow.json`
4. Click Import
5. Verify all nodes are properly loaded

### 4. Credential Configuration

For each credential file in the `credentials/` folder:

1. In n8n, go to Credentials
2. Click "Add Credential"
3. Select the appropriate credential type
4. Enter the configuration from the JSON file
5. Update with your actual API keys/passwords
6. Test the connection
7. Save the credential

#### Example: OTX Credentials Setup
```json
{
  "name": "X-OTX-API-KEY",
  "value": "your_actual_otx_api_key_here"
}
```

### 5. Workflow Configuration

1. Open the imported workflow
2. Click on each node to verify configurations
3. Update any hardcoded values (emails, channels, etc.)
4. Test individual nodes by clicking "Test step"
5. Fix any configuration errors

### 6. Slack Integration Setup

#### Create Slack App
1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. App name: "Threat Intelligence Bot"
4. Select your workspace

#### Configure Permissions
1. Go to OAuth & Permissions
2. Add Bot Token Scopes:
   - `channels:read`
   - `chat:write`
   - `chat:write.public`
3. Install App to Workspace
4. Copy "Bot User OAuth Token"

#### Create Channel
1. In Slack, create #threat-intel channel
2. Invite the bot to the channel: `/invite @threat-intelligence-bot`

### 7. Email Configuration

#### IMAP Setup
```json
{
  "host": "imap.gmail.com",
  "port": 993,
  "secure": true,
  "user": "threat-intel@company.com",
  "password": "app_specific_password"
}
```

#### SMTP Setup
```json
{
  "host": "smtp.gmail.com",
  "port": 587,
  "secure": false,
  "user": "threat-intel@company.com",
  "password": "app_specific_password"
}
```

### 8. Testing the Installation

#### Test Database Connection
```bash
psql -h localhost -U ti_user -d threat_intelligence -c "SELECT version();"
```

#### Test Webhook
```bash
curl -X POST "https://your-n8n-instance/webhook/threat-intel" \
  -H "Content-Type: application/json" \
  -d '{
    "ip_address": "8.8.8.8",
    "source": "test",
    "confidence": 50
  }'
```

#### Test Workflow Execution
1. In n8n, open the workflow
2. Click "Test workflow"
3. Use the webhook trigger with test data
4. Monitor execution progress
5. Check database for stored results
6. Verify no errors in execution log

### 9. Production Deployment

#### Security Hardening
- Change default passwords
- Enable SSL/TLS everywhere
- Configure firewall rules
- Set up monitoring and logging
- Implement backup strategy

#### Performance Optimization
```bash
# PostgreSQL tuning (add to postgresql.conf)
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 8MB
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
max_connections = 200
```

#### Monitoring Setup
- Configure PostgreSQL logging
- Set up n8n execution monitoring
- Implement health checks
- Monitor disk space and performance

### 10. Grafana Dashboard Setup (Optional)

#### Install Grafana
```bash
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

#### Configure Data Source
1. Login to Grafana (admin/admin)
2. Go to Configuration → Data Sources
3. Add PostgreSQL data source:
   - Host: localhost:5432
   - Database: threat_intelligence
   - User: ti_user
   - Password: your_password
   - SSL Mode: require

#### Import Dashboard
1. Go to + → Import
2. Upload `grafana-dashboard.json`
3. Configure data source mapping
4. Save and view dashboard

## Verification Checklist

- [ ] PostgreSQL database accessible and schema applied
- [ ] n8n workflow imported and activated
- [ ] All credentials configured and tested
- [ ] API keys valid and working
- [ ] Slack integration working
- [ ] Email configuration working
- [ ] Webhook endpoint accessible
- [ ] Test execution successful
- [ ] Data stored in database
- [ ] Alerts triggered for high-threat IOCs
- [ ] Grafana dashboard displaying data (optional)

## Common Installation Issues

### Database Connection Errors
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -h localhost -U ti_user -d threat_intelligence -c "\l"

# Check firewall/port access
telnet localhost 5432
```

### API Authentication Failures
```bash
# Test each API individually
curl -H "X-OTX-API-KEY: YOUR_KEY" https://otx.alienvault.com/api/v1/user/me
curl -H "x-apikey: YOUR_KEY" https://www.virustotal.com/vtapi/v2/ip-address/report?ip=8.8.8.8
```

### n8n Workflow Errors
- Check node configurations match credential names
- Verify all required credentials are created
- Test nodes individually before running full workflow
- Check n8n logs for detailed error messages

### Memory/Performance Issues
```bash
# Monitor system resources
htop
free -m
df -h

# Check PostgreSQL performance
SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;
```

## Post-Installation Configuration

1. **Adjust Rate Limits**: Modify rate limiting based on your API quotas
2. **Customize Scoring**: Adjust threat scoring algorithm weights
3. **Configure Retention**: Set appropriate data retention policies
4. **Set up Monitoring**: Implement alerting for system health
5. **Create Backups**: Schedule regular database backups
6. **Document Changes**: Keep track of any customizations

## Next Steps

After successful installation:
1. Review the main README.md for usage instructions
2. Test with real threat intelligence data
3. Configure additional data sources as needed
4. Set up monitoring and alerting
5. Train users on the system capabilities
6. Establish operational procedures

For troubleshooting help, see the Troubleshooting section in the main README.md file.