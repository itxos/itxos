# AI-Powered Threat Intelligence System

## Project Overview

This project provides a comprehensive, AI-powered threat intelligence system built on n8n workflows. It automatically collects, processes, enriches, and analyzes threat indicators from multiple sources, providing real-time threat assessment with artificial intelligence.

## 🚀 Key Features

- **Multi-Source Data Collection**: Webhook and email triggers for flexible threat data ingestion
- **STIX-Compatible Normalization**: Standardized threat intelligence format following STIX 2.1 specifications
- **Intelligent Deduplication**: Prevents duplicate processing while updating confidence scores
- **6-Source Enrichment**: Integrates with OTX, VirusTotal, GreyNoise, Shodan, AbuseIPDB, and geolocation APIs
- **AI-Powered Analysis**: OpenAI GPT integration for threat summarization and prioritization
- **Advanced Threat Scoring**: Algorithmic risk assessment with 0-100 scoring system
- **Real-Time Alerting**: Slack and email notifications for high-threat indicators
- **Comprehensive Storage**: PostgreSQL database with full audit trail and relationships
- **Performance Monitoring**: Built-in rate limiting and execution tracking
- **Visual Dashboards**: Grafana integration with 10 pre-built visualizations

## 📊 System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Data Sources  │───▶│   n8n Workflow   │───▶│   PostgreSQL DB     │
│                 │    │                  │    │                     │
│ • Webhooks      │    │ • Normalization  │    │ • Threat Intel      │
│ • Email IMAP    │    │ • Deduplication  │    │ • Enrichment Data   │
│ • Manual Input  │    │ • Enrichment     │    │ • Alerts History    │
│ • APIs          │    │ • AI Analysis    │    │ • Metrics           │
└─────────────────┘    │ • Scoring        │    └─────────────────────┘
                       │ • Alerting       │             │
                       └──────────────────┘             │
                                │                       │
┌──────────────────────────────────┐                     │
│        Threat Intel APIs         │                     │
│ • AlienVault OTX                │                     │
│ • VirusTotal                     │                     │
│ • GreyNoise                      │         ┌───────────▼────────────┐
│ • Shodan                         │         │     Grafana Dashboard  │
│ • AbuseIPDB                      │         │                        │
│ • IP Geolocation                 │         │ • Real-time Metrics    │
└──────────────────────────────────┘         │ • Threat Visualizations│
                                             │ • Performance Monitoring│
                                             └────────────────────────┘
```

## 🎯 Use Cases

### Security Operations Centers (SOCs)
- Automated threat intelligence processing
- Real-time threat scoring and prioritization  
- Integration with existing security tools
- Centralized threat indicator management

### Incident Response Teams
- Rapid IOC enrichment and analysis
- AI-powered threat assessment summaries
- Historical threat intelligence lookups
- Contextual threat information

### Threat Intelligence Teams
- Multi-source intelligence aggregation
- Automated threat actor attribution
- Campaign and malware family tracking
- Intelligence sharing and collaboration

### Managed Security Service Providers (MSSPs)
- Multi-tenant threat intelligence processing
- Automated client alerting and reporting
- Scalable threat analysis workflows
- Performance and SLA monitoring

## 📋 File Structure

```
n8n-threat-intelligence/
├── workflows/
│   └── ai-threat-intelligence-workflow.json  # Main n8n workflow
├── credentials/
│   ├── otx-credentials.json                  # AlienVault OTX API
│   ├── virustotal-credentials.json           # VirusTotal API
│   ├── greynoise-credentials.json            # GreyNoise API
│   ├── shodan-credentials.json               # Shodan API
│   ├── abuseipdb-credentials.json            # AbuseIPDB API
│   ├── openai-credentials.json               # OpenAI GPT API
│   ├── postgresql-credentials.json           # Database connection
│   ├── slack-credentials.json                # Slack bot token
│   ├── smtp-credentials.json                 # Email sending
│   └── email-credentials.json                # Email receiving (IMAP)
├── database/
│   └── schema.sql                            # PostgreSQL database schema
├── documentation/
│   ├── INSTALLATION.md                       # Step-by-step installation guide
│   └── CONFIGURATION.md                      # Detailed configuration options
├── grafana-dashboard.json                    # Grafana dashboard configuration
└── README.md                                 # Main documentation
```

## 🔧 Quick Start

### Prerequisites
- n8n instance (v1.0+)
- PostgreSQL database (v12+)
- API keys for threat intelligence sources
- OpenAI API key
- Slack workspace (optional)

### Installation Steps
1. **Database Setup**: Create PostgreSQL database and apply schema
2. **n8n Configuration**: Import workflow and configure credentials
3. **API Keys**: Configure all threat intelligence source APIs
4. **Testing**: Verify workflow execution with test data
5. **Monitoring**: Set up Grafana dashboards (optional)

See `documentation/INSTALLATION.md` for detailed instructions.

## 🎨 Workflow Components

### Data Collection Layer
- **Webhook Trigger**: RESTful API endpoint for real-time IOC submission
- **Email Trigger**: IMAP integration for email-based threat intelligence
- **Rate Limiter**: Intelligent API call management and throttling

### Processing Layer
- **Data Normalization**: STIX 2.1 compatible format conversion
- **Deduplication Engine**: Prevents duplicate processing with confidence updates
- **Route by Type**: IOC type-based processing routing

### Enrichment Layer
- **Multi-Source APIs**: 6 threat intelligence sources
- **Parallel Processing**: Concurrent API calls for performance
- **Error Handling**: Robust retry mechanisms and fallback logic

### Analysis Layer
- **Threat Scoring**: Advanced algorithmic risk assessment
- **AI Summarization**: OpenAI GPT-powered threat analysis
- **Relationship Mapping**: IOC correlation and attribution

### Storage Layer
- **PostgreSQL Database**: Structured threat intelligence storage
- **Full Audit Trail**: Complete processing history and lineage
- **Performance Optimization**: Indexed queries and partitioning

### Alerting Layer
- **Smart Thresholds**: Configurable threat level alerting
- **Multi-Channel Alerts**: Slack and email notifications
- **Rich Context**: AI summaries and actionable intelligence

## 📈 Threat Scoring Algorithm

The system uses a weighted scoring algorithm considering:

| Source | Weight | Factors |
|--------|--------|---------|
| **Base Confidence** | 10% | Original indicator confidence |
| **OTX Intelligence** | 25% | Pulse count, malware families |
| **VirusTotal** | 30% | Detections, malicious samples |
| **GreyNoise** | 20% | Scanner activity, legitimacy |
| **Shodan** | 25% | Open ports, vulnerabilities |
| **AbuseIPDB** | 30% | Abuse reports, confidence |
| **Geolocation** | 15% | Country risk, hosting type |

**Threat Levels:**
- 🟢 **LOW** (0-29): Minimal risk
- 🟡 **MEDIUM** (30-49): Moderate risk
- 🟠 **HIGH** (50-69): Significant risk - alerts triggered
- 🔴 **CRITICAL** (70-100): Severe risk - immediate alerts

## 🔒 Security Features

- **API Key Management**: Secure credential storage in n8n
- **Rate Limiting**: Prevents API abuse and quota exhaustion
- **Data Encryption**: TLS/SSL for all external communications
- **Access Control**: Role-based permissions and authentication
- **Audit Logging**: Complete activity and access logging
- **Data Retention**: Configurable retention and cleanup policies

## 📊 Monitoring & Analytics

### Real-Time Metrics
- Total IOCs processed
- Threat level distribution
- Processing performance
- API success rates
- Alert activity

### Historical Analysis
- Threat trends over time
- Source reliability metrics
- Campaign attribution
- False positive tracking

### Performance Monitoring
- API response times
- Database query performance
- Workflow execution metrics
- Resource utilization

## 🤝 Integration Options

### Input Methods
- **REST API**: Direct webhook integration
- **Email**: Forward threat intelligence emails
- **Bulk Import**: CSV/JSON file processing
- **Manual Entry**: n8n interface input

### Output Methods
- **Database**: PostgreSQL storage
- **Alerts**: Slack/email notifications  
- **APIs**: RESTful query endpoints
- **Exports**: CSV/JSON/STIX formats

### External Tools
- **SIEM Integration**: Log forwarding and API queries
- **Ticketing Systems**: Automated ticket creation
- **Threat Hunting**: IOC pivot and investigation
- **Incident Response**: Context and attribution

## 🚀 Advanced Features

### AI-Powered Capabilities
- **Natural Language Summaries**: Human-readable threat assessments
- **Contextual Analysis**: Campaign and actor attribution
- **Risk Prioritization**: Intelligent threat ranking
- **Predictive Analysis**: Emerging threat identification

### Automation Features
- **Auto-Classification**: IOC type and threat level assignment
- **Smart Routing**: Context-aware processing workflows
- **Adaptive Learning**: Confidence score optimization
- **Bulk Processing**: High-volume data handling

### Scalability Features
- **Horizontal Scaling**: Multi-node n8n deployment
- **Database Partitioning**: Time-based data organization
- **Caching Layer**: Redis integration for performance
- **Load Balancing**: Distributed processing capabilities

## 📚 Documentation

- **README.md**: Main project documentation and overview
- **INSTALLATION.md**: Detailed installation and setup guide
- **CONFIGURATION.md**: Comprehensive configuration options
- **API Reference**: Webhook and query API documentation
- **Troubleshooting**: Common issues and solutions

## 🤖 AI Integration

The system leverages OpenAI's GPT models for:

### Threat Analysis
- Contextual threat assessment
- Risk factor identification
- Mitigation recommendations
- Attribution analysis

### Natural Language Processing
- IOC extraction from text
- Email content analysis
- Report summarization
- Query interpretation

### Predictive Capabilities
- Threat trend analysis
- Campaign detection
- Anomaly identification
- Risk forecasting

## 🔮 Future Enhancements

### Planned Features
- **Machine Learning**: Custom threat scoring models
- **Behavioral Analysis**: Anomaly detection capabilities
- **Threat Hunting**: Interactive investigation tools
- **Mobile App**: Real-time alerts and dashboards

### Integration Roadmap
- **MISP Integration**: Threat sharing platform
- **TAXII Support**: Standardized threat intelligence exchange
- **STIX 2.1 Export**: Full specification compliance
- **Additional APIs**: Expanded enrichment sources

## 🏆 Benefits

### For Security Teams
- **Reduced Manual Work**: 90% automation of threat analysis
- **Faster Response**: Real-time threat identification
- **Better Context**: AI-powered threat intelligence
- **Improved Accuracy**: Multi-source validation

### For Organizations  
- **Cost Reduction**: Automated threat intelligence processing
- **Risk Mitigation**: Proactive threat identification
- **Compliance**: Audit trail and documentation
- **Scalability**: Handles increasing threat volumes

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines and:
- Report bugs and feature requests
- Submit pull requests with improvements
- Share configuration examples
- Contribute documentation

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and assistance:
- Check the troubleshooting documentation
- Review configuration examples
- Submit issues on GitHub
- Join our community discussions

---

**Ready to deploy intelligent threat analysis?** Start with the installation guide and transform your security operations with AI-powered threat intelligence!