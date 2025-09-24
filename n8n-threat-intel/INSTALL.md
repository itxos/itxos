# Installation & Setup Guide

This guide provides step-by-step instructions for installing and configuring the n8n AI Threat Intelligence System.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Steps](#installation-steps)
3. [Configuration](#configuration)
4. [Testing](#testing)
5. [Production Deployment](#production-deployment)
6. [Monitoring Setup](#monitoring-setup)

## System Requirements

### Hardware Requirements

**Minimum (Development/Testing)**:
- CPU: 2 cores
- RAM: 4GB
- Storage: 20GB SSD
- Network: 10 Mbps

**Recommended (Production)**:
- CPU: 4+ cores
- RAM: 8GB+
- Storage: 100GB+ SSD
- Network: 100 Mbps+

### Software Requirements

- **Operating System**: Ubuntu 20.04+ / CentOS 8+ / Docker
- **Node.js**: 16.x or higher
- **PostgreSQL**: 12.x or higher
- **n8n**: 1.0.0 or higher
- **Grafana**: 8.0.0 or higher

### Network Requirements

- Outbound internet access for API calls
- Inbound access for webhooks (if applicable)
- SMTP/IMAP access for email integration

## Installation Steps

### Step 1: Install Dependencies

#### Ubuntu/Debian

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Install Git and other utilities
sudo apt install git curl wget unzip -y
```

#### CentOS/RHEL

```bash
# Update system packages
sudo yum update -y

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install PostgreSQL
sudo yum install postgresql-server postgresql-contrib -y
sudo postgresql-setup initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Install Git and other utilities
sudo yum install git curl wget unzip -y
```

### Step 2: Install n8n

```bash
# Install n8n globally
npm install -g n8n

# Verify installation
n8n --version
```

### Step 3: Setup PostgreSQL Database

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE threat_intel;
CREATE USER threat_intel_app WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE threat_intel TO threat_intel_app;

# Create read-only user for Grafana
CREATE USER threat_intel_readonly WITH ENCRYPTED PASSWORD 'another_secure_password';

# Exit psql
\q
```

Apply the database schema:

```bash
# Download schema file
wget https://raw.githubusercontent.com/your-repo/n8n-threat-intel/main/schema.sql

# Apply schema
psql -U threat_intel_app -d threat_intel -f schema.sql
```

### Step 4: Configure Environment

Create environment configuration:

```bash
# Create .env file
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=threat_intel
DB_USERNAME=threat_intel_app
DB_PASSWORD=your_secure_password

# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_admin_password

# API Keys (replace with actual keys)
OPENAI_API_KEY=sk-your-openai-key
VIRUSTOTAL_API_KEY=your-virustotal-key
ABUSEIPDB_API_KEY=your-abuseipdb-key

# Slack Configuration
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_CHANNEL=#threat-alerts

# Email Configuration
SMTP_HOST=smtp.company.com
SMTP_PORT=587
SMTP_USER=threat-intel@company.com
SMTP_PASSWORD=smtp_password
SECURITY_TEAM_EMAIL=security-team@company.com

# IMAP Configuration
IMAP_HOST=imap.company.com
IMAP_PORT=993
IMAP_USER=threat-intel@company.com
IMAP_PASSWORD=imap_password

# Security
API_KEY=your-api-key-for-webhooks
WEBHOOK_SECRET=your-webhook-secret
EOF

# Secure the environment file
chmod 600 .env
```

### Step 5: Start n8n

```bash
# Load environment variables and start n8n
source .env
n8n start
```

Access n8n web interface at `http://localhost:5678`

### Step 6: Import Workflow

1. Open n8n web interface
2. Navigate to **Workflows**
3. Click **Import from file**
4. Upload the `workflow.json` file
5. Click **Save**

### Step 7: Configure Credentials

Configure the following credentials in n8n:

#### PostgreSQL Connection
- **Name**: `Threat Intel DB`
- **Host**: `localhost`
- **Database**: `threat_intel`
- **User**: `threat_intel_app`
- **Password**: Your database password
- **SSL**: Enable if using SSL

#### OpenAI API
- **Name**: `OpenAI API`
- **API Key**: Your OpenAI API key
- **Organization**: Your OpenAI organization (optional)

#### VirusTotal API
- **Name**: `VirusTotal API`
- **API Key**: Your VirusTotal API key

#### AbuseIPDB API
- **Name**: `AbuseIPDB API`
- **API Key**: Your AbuseIPDB API key

#### Slack Bot
- **Name**: `Security Team Slack`
- **Bot Token**: Your Slack bot token

#### SMTP
- **Name**: `Company SMTP`
- **Host**: Your SMTP host
- **Port**: SMTP port (usually 587)
- **User**: SMTP username
- **Password**: SMTP password
- **Security**: STARTTLS

#### IMAP
- **Name**: `Threat Intel Email`
- **Host**: Your IMAP host
- **Port**: IMAP port (usually 993)
- **User**: IMAP username
- **Password**: IMAP password
- **Security**: SSL

## Configuration

### Webhook URL

Note your webhook URL for external integrations:
```
https://your-domain.com/webhook/threat-intel-webhook
```

### Email Integration

Configure email forwarding to send threat intelligence emails to the IMAP mailbox configured in n8n.

### API Rate Limits

The system automatically manages API rate limits. Monitor usage in the database:

```sql
SELECT * FROM api_rate_limits;
```

## Testing

### Test Webhook Integration

```bash
# Test with sample threat data
curl -X POST http://localhost:5678/webhook/threat-intel-webhook \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key-for-webhooks" \
  -d '{
    "source": "test",
    "severity": "medium",
    "confidence": 75,
    "tlp": "GREEN",
    "ips": ["8.8.8.8"],
    "domains": ["test-domain.com"],
    "description": "Test threat intelligence data"
  }'
```

### Test Database Connection

```bash
# Verify data was stored
psql -U threat_intel_app -d threat_intel -c "SELECT * FROM threat_intel ORDER BY timestamp DESC LIMIT 5;"
```

### Test Email Integration

Send a test email to the configured IMAP mailbox with IOCs in the content.

### Test Alerting

Verify alerts are sent to configured channels (Slack, email).

## Production Deployment

### Using Docker

Create a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=threat_intel
      - DB_POSTGRESDB_USER=threat_intel_app
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres

  postgres:
    image: postgres:13
    environment:
      - POSTGRES_DB=threat_intel
      - POSTGRES_USER=threat_intel_app
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./dashboard.json:/etc/grafana/provisioning/dashboards/dashboard.json

volumes:
  n8n_data:
  postgres_data:
  grafana_data:
```

Start the stack:

```bash
docker-compose up -d
```

### Using Systemd

Create systemd service:

```bash
# Create service file
sudo cat > /etc/systemd/system/n8n-threat-intel.service << EOF
[Unit]
Description=n8n AI Threat Intelligence System
After=network.target postgresql.service

[Service]
Type=simple
User=n8n
WorkingDirectory=/opt/n8n-threat-intel
EnvironmentFile=/opt/n8n-threat-intel/.env
ExecStart=/usr/bin/n8n start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create user and directories
sudo useradd -r -s /bin/false n8n
sudo mkdir -p /opt/n8n-threat-intel
sudo cp .env /opt/n8n-threat-intel/
sudo chown -R n8n:n8n /opt/n8n-threat-intel

# Enable and start service
sudo systemctl enable n8n-threat-intel
sudo systemctl start n8n-threat-intel
```

### Reverse Proxy (Nginx)

Configure Nginx for SSL termination:

```nginx
server {
    listen 80;
    server_name threat-intel.company.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name threat-intel.company.com;

    ssl_certificate /path/to/ssl/cert.pem;
    ssl_certificate_key /path/to/ssl/key.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Monitoring Setup

### Install Grafana

```bash
# Add Grafana repository
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt update
sudo apt install grafana -y

# Start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Configure Grafana

1. Access Grafana at `http://localhost:3000`
2. Login with admin/admin
3. Add PostgreSQL datasource:
   - **Host**: `localhost:5432`
   - **Database**: `threat_intel`
   - **User**: `threat_intel_readonly`
   - **Password**: Read-only user password
   - **SSL Mode**: require (if using SSL)

4. Import dashboard from `dashboard.json`

### Health Monitoring

Set up automated health checks:

```bash
# Create health check script
cat > /opt/n8n-threat-intel/health-check.sh << 'EOF'
#!/bin/bash

# Check n8n service
if ! systemctl is-active --quiet n8n-threat-intel; then
    echo "ERROR: n8n service is not running"
    exit 1
fi

# Check database connectivity
if ! pg_isready -h localhost -p 5432 -U threat_intel_app; then
    echo "ERROR: Database is not responding"
    exit 1
fi

# Check webhook endpoint
if ! curl -f -s http://localhost:5678/webhook/threat-intel-webhook > /dev/null; then
    echo "ERROR: Webhook endpoint not responding"
    exit 1
fi

echo "All systems operational"
EOF

chmod +x /opt/n8n-threat-intel/health-check.sh

# Add to crontab
echo "*/5 * * * * /opt/n8n-threat-intel/health-check.sh" | sudo crontab -
```

## Next Steps

1. **Test thoroughly**: Run comprehensive tests with sample data
2. **Configure monitoring**: Set up alerts for system health
3. **Documentation**: Create runbooks for common operations
4. **Backup strategy**: Implement automated database backups
5. **Security hardening**: Review security configurations
6. **User training**: Train team members on system usage

For troubleshooting and additional configuration, see the main [README.md](README.md) file.