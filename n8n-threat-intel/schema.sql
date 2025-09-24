-- PostgreSQL Database Schema for n8n AI Threat Intelligence System
-- Created: 2024-01-01
-- Purpose: Store threat intelligence data, IOCs, analysis results, and system metrics

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Drop existing schema if exists (use with caution in production)
-- DROP SCHEMA IF EXISTS threat_intel CASCADE;

-- Create schema
CREATE SCHEMA IF NOT EXISTS threat_intel;
SET search_path TO threat_intel, public;

-- =======================
-- MAIN THREAT DATA TABLE
-- =======================
CREATE TABLE threat_intel (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source VARCHAR(255) NOT NULL DEFAULT 'unknown',
    severity VARCHAR(20) NOT NULL DEFAULT 'medium' 
        CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')),
    confidence INTEGER NOT NULL DEFAULT 50 
        CHECK (confidence >= 0 AND confidence <= 100),
    tlp VARCHAR(10) NOT NULL DEFAULT 'WHITE' 
        CHECK (tlp IN ('RED', 'AMBER', 'GREEN', 'WHITE')),
    
    -- IOCs stored as JSONB for flexible querying
    iocs JSONB NOT NULL DEFAULT '{}',
    
    -- Analysis results
    threat_score DECIMAL(4,1) DEFAULT 0.0 
        CHECK (threat_score >= 0.0 AND threat_score <= 100.0),
    alert_level VARCHAR(20) DEFAULT 'info' 
        CHECK (alert_level IN ('critical', 'high', 'medium', 'low', 'info')),
    
    -- External API analysis results
    external_analysis JSONB DEFAULT '{}',
    
    -- AI recommendations
    recommendations JSONB DEFAULT '[]',
    
    -- Processing status
    processed BOOLEAN DEFAULT FALSE,
    analysis_timestamp TIMESTAMPTZ,
    
    -- Raw data for audit and reprocessing
    raw_data JSONB,
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Retention management
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 year')
);

-- =======================
-- IOC TRACKING TABLE
-- =======================
CREATE TABLE ioc_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ioc_value TEXT NOT NULL,
    ioc_type VARCHAR(20) NOT NULL 
        CHECK (ioc_type IN ('ip', 'domain', 'hash', 'url', 'email', 'filename')),
    threat_id UUID REFERENCES threat_intel(id) ON DELETE CASCADE,
    first_seen TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    hit_count INTEGER DEFAULT 1,
    
    -- Reputation data
    reputation_score DECIMAL(4,1) DEFAULT 0.0,
    whitelist_status BOOLEAN DEFAULT FALSE,
    blacklist_status BOOLEAN DEFAULT FALSE,
    
    -- Geographic and network data
    geo_data JSONB DEFAULT '{}',
    network_data JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================
-- ALERT HISTORY TABLE
-- =======================
CREATE TABLE alert_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    threat_id UUID REFERENCES threat_intel(id) ON DELETE CASCADE,
    alert_type VARCHAR(20) NOT NULL 
        CHECK (alert_type IN ('email', 'slack', 'webhook', 'sms', 'syslog')),
    alert_level VARCHAR(20) NOT NULL,
    recipient TEXT NOT NULL,
    subject TEXT,
    message TEXT,
    
    -- Delivery status
    status VARCHAR(20) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'retrying')),
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================
-- SYSTEM METRICS TABLE
-- =======================
CREATE TABLE system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(12,4) NOT NULL,
    metric_type VARCHAR(20) NOT NULL DEFAULT 'gauge' 
        CHECK (metric_type IN ('gauge', 'counter', 'histogram', 'summary')),
    labels JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================
-- API RATE LIMITING TABLE
-- =======================
CREATE TABLE api_rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(50) NOT NULL,
    endpoint VARCHAR(200) NOT NULL,
    requests_made INTEGER DEFAULT 0,
    requests_limit INTEGER NOT NULL,
    reset_time TIMESTAMPTZ NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(service_name, endpoint, reset_time)
);

-- =======================
-- ERROR LOG TABLE
-- =======================
CREATE TABLE error_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    error_details JSONB DEFAULT '{}',
    node_name VARCHAR(100),
    workflow_id VARCHAR(100),
    execution_id VARCHAR(100),
    
    -- Categorization
    severity VARCHAR(20) DEFAULT 'medium' 
        CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    category VARCHAR(50) DEFAULT 'general' 
        CHECK (category IN ('general', 'api', 'database', 'network', 'parsing', 'authentication')),
    
    -- Resolution tracking
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================
-- INDEXES FOR PERFORMANCE
-- =======================

-- Primary threat data indexes
CREATE INDEX idx_threat_intel_timestamp ON threat_intel(timestamp);
CREATE INDEX idx_threat_intel_source ON threat_intel(source);
CREATE INDEX idx_threat_intel_severity ON threat_intel(severity);
CREATE INDEX idx_threat_intel_alert_level ON threat_intel(alert_level);
CREATE INDEX idx_threat_intel_processed ON threat_intel(processed);
CREATE INDEX idx_threat_intel_threat_score ON threat_intel(threat_score);

-- JSONB indexes for IOCs (crucial for deduplication)
CREATE INDEX idx_threat_intel_iocs_gin ON threat_intel USING GIN(iocs);
CREATE INDEX idx_threat_intel_iocs_ips ON threat_intel USING GIN((iocs->'ips'));
CREATE INDEX idx_threat_intel_iocs_domains ON threat_intel USING GIN((iocs->'domains'));
CREATE INDEX idx_threat_intel_iocs_hashes ON threat_intel USING GIN((iocs->'hashes'));
CREATE INDEX idx_threat_intel_iocs_urls ON threat_intel USING GIN((iocs->'urls'));

-- External analysis indexes
CREATE INDEX idx_threat_intel_external_analysis ON threat_intel USING GIN(external_analysis);

-- IOC tracking indexes
CREATE INDEX idx_ioc_tracking_value_type ON ioc_tracking(ioc_value, ioc_type);
CREATE INDEX idx_ioc_tracking_threat_id ON ioc_tracking(threat_id);
CREATE INDEX idx_ioc_tracking_first_seen ON ioc_tracking(first_seen);
CREATE INDEX idx_ioc_tracking_last_seen ON ioc_tracking(last_seen);
CREATE INDEX idx_ioc_tracking_reputation ON ioc_tracking(reputation_score);
CREATE INDEX idx_ioc_tracking_whitelist ON ioc_tracking(whitelist_status) WHERE whitelist_status = TRUE;
CREATE INDEX idx_ioc_tracking_blacklist ON ioc_tracking(blacklist_status) WHERE blacklist_status = TRUE;

-- Text search index for IOC values
CREATE INDEX idx_ioc_tracking_value_trgm ON ioc_tracking USING GIN(ioc_value gin_trgm_ops);

-- Alert history indexes
CREATE INDEX idx_alert_history_threat_id ON alert_history(threat_id);
CREATE INDEX idx_alert_history_status ON alert_history(status);
CREATE INDEX idx_alert_history_sent_at ON alert_history(sent_at);
CREATE INDEX idx_alert_history_alert_type ON alert_history(alert_type);

-- System metrics indexes
CREATE INDEX idx_system_metrics_name_timestamp ON system_metrics(metric_name, timestamp);
CREATE INDEX idx_system_metrics_timestamp ON system_metrics(timestamp);
CREATE INDEX idx_system_metrics_labels ON system_metrics USING GIN(labels);

-- Rate limiting indexes
CREATE INDEX idx_api_rate_limits_service ON api_rate_limits(service_name);
CREATE INDEX idx_api_rate_limits_reset_time ON api_rate_limits(reset_time);

-- Error log indexes
CREATE INDEX idx_error_log_timestamp ON error_log(created_at);
CREATE INDEX idx_error_log_severity ON error_log(severity);
CREATE INDEX idx_error_log_category ON error_log(category);
CREATE INDEX idx_error_log_resolved ON error_log(resolved) WHERE resolved = FALSE;
CREATE INDEX idx_error_log_node_name ON error_log(node_name);

-- =======================
-- VIEWS FOR REPORTING
-- =======================

-- Active threats view
CREATE OR REPLACE VIEW v_active_threats AS
SELECT 
    t.id,
    t.timestamp,
    t.source,
    t.severity,
    t.threat_score,
    t.alert_level,
    t.iocs,
    t.recommendations,
    t.analysis_timestamp,
    EXTRACT(HOUR FROM AGE(NOW(), t.timestamp)) as hours_since_detection,
    COUNT(ah.id) as alert_count
FROM threat_intel t
LEFT JOIN alert_history ah ON t.id = ah.threat_id
WHERE t.processed = TRUE 
    AND t.alert_level IN ('critical', 'high', 'medium')
    AND t.timestamp >= NOW() - INTERVAL '7 days'
GROUP BY t.id, t.timestamp, t.source, t.severity, t.threat_score, 
         t.alert_level, t.iocs, t.recommendations, t.analysis_timestamp
ORDER BY t.threat_score DESC, t.timestamp DESC;

-- IOC intelligence view
CREATE OR REPLACE VIEW v_ioc_intelligence AS
SELECT 
    ioc.ioc_value,
    ioc.ioc_type,
    ioc.first_seen,
    ioc.last_seen,
    ioc.hit_count,
    ioc.reputation_score,
    ioc.whitelist_status,
    ioc.blacklist_status,
    COUNT(DISTINCT t.id) as associated_threats,
    MAX(t.threat_score) as max_threat_score,
    array_agg(DISTINCT t.source) as sources,
    array_agg(DISTINCT t.alert_level) as alert_levels
FROM ioc_tracking ioc
LEFT JOIN threat_intel t ON ioc.threat_id = t.id
GROUP BY ioc.ioc_value, ioc.ioc_type, ioc.first_seen, ioc.last_seen,
         ioc.hit_count, ioc.reputation_score, ioc.whitelist_status, ioc.blacklist_status
ORDER BY ioc.reputation_score DESC, ioc.hit_count DESC;

-- Daily threat summary view
CREATE OR REPLACE VIEW v_daily_threat_summary AS
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as total_threats,
    COUNT(*) FILTER (WHERE alert_level = 'critical') as critical_threats,
    COUNT(*) FILTER (WHERE alert_level = 'high') as high_threats,
    COUNT(*) FILTER (WHERE alert_level = 'medium') as medium_threats,
    COUNT(*) FILTER (WHERE alert_level = 'low') as low_threats,
    AVG(threat_score) as avg_threat_score,
    array_agg(DISTINCT source) as sources,
    COUNT(DISTINCT source) as unique_sources
FROM threat_intel
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
    AND processed = TRUE
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- System health view
CREATE OR REPLACE VIEW v_system_health AS
SELECT 
    'threats_processed_24h' as metric,
    COUNT(*) as value,
    'count' as type
FROM threat_intel 
WHERE processed = TRUE 
    AND timestamp >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'avg_processing_time_minutes' as metric,
    AVG(EXTRACT(EPOCH FROM (analysis_timestamp - timestamp))/60) as value,
    'gauge' as type
FROM threat_intel 
WHERE processed = TRUE 
    AND analysis_timestamp IS NOT NULL
    AND timestamp >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'active_errors_24h' as metric,
    COUNT(*) as value,
    'count' as type
FROM error_log 
WHERE created_at >= NOW() - INTERVAL '24 hours'
    AND resolved = FALSE
UNION ALL
SELECT 
    'successful_alerts_24h' as metric,
    COUNT(*) as value,
    'count' as type
FROM alert_history 
WHERE sent_at >= NOW() - INTERVAL '24 hours'
    AND status = 'delivered';

-- =======================
-- TRIGGERS FOR AUTOMATION
-- =======================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp triggers to relevant tables
CREATE TRIGGER trigger_threat_intel_timestamp 
    BEFORE UPDATE ON threat_intel 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_ioc_tracking_timestamp 
    BEFORE UPDATE ON ioc_tracking 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_alert_history_timestamp 
    BEFORE UPDATE ON alert_history 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_api_rate_limits_timestamp 
    BEFORE UPDATE ON api_rate_limits 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_error_log_timestamp 
    BEFORE UPDATE ON error_log 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- IOC tracking trigger function
CREATE OR REPLACE FUNCTION update_ioc_tracking()
RETURNS TRIGGER AS $$
DECLARE
    ioc_key TEXT;
    ioc_value TEXT;
    ioc_array JSONB;
BEGIN
    -- Process each IOC type
    FOR ioc_key IN SELECT * FROM jsonb_object_keys(NEW.iocs) LOOP
        ioc_array := NEW.iocs->ioc_key;
        
        -- Extract IOC type (remove 's' suffix)
        IF ioc_array IS NOT NULL AND jsonb_array_length(ioc_array) > 0 THEN
            FOR i IN 0..jsonb_array_length(ioc_array)-1 LOOP
                ioc_value := ioc_array->>i;
                
                -- Insert or update IOC tracking
                INSERT INTO ioc_tracking (ioc_value, ioc_type, threat_id, last_seen, hit_count)
                VALUES (ioc_value, rtrim(ioc_key, 's'), NEW.id, NEW.timestamp, 1)
                ON CONFLICT (ioc_value, ioc_type, threat_id) 
                DO UPDATE SET 
                    last_seen = NEW.timestamp,
                    hit_count = ioc_tracking.hit_count + 1;
            END LOOP;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply IOC tracking trigger
CREATE TRIGGER trigger_ioc_extraction 
    AFTER INSERT ON threat_intel 
    FOR EACH ROW EXECUTE FUNCTION update_ioc_tracking();

-- =======================
-- STORED PROCEDURES
-- =======================

-- Clean up old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- Delete expired threat intelligence data
    DELETE FROM threat_intel 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Delete old system metrics (older than 90 days)
    DELETE FROM system_metrics 
    WHERE timestamp < NOW() - INTERVAL '90 days';
    
    -- Delete resolved errors older than 30 days
    DELETE FROM error_log 
    WHERE resolved = TRUE 
        AND resolved_at < NOW() - INTERVAL '30 days';
    
    -- Delete old rate limit entries
    DELETE FROM api_rate_limits 
    WHERE reset_time < NOW() - INTERVAL '24 hours';
    
    -- Log cleanup action
    INSERT INTO system_metrics (metric_name, metric_value, metric_type, labels)
    VALUES ('cleanup_deleted_records', deleted_count, 'counter', 
            jsonb_build_object('table', 'threat_intel', 'action', 'cleanup'));
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Get IOC reputation
CREATE OR REPLACE FUNCTION get_ioc_reputation(ioc_val TEXT, ioc_typ TEXT)
RETURNS TABLE(reputation_score DECIMAL, hit_count INTEGER, first_seen TIMESTAMPTZ, threat_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        it.reputation_score,
        it.hit_count,
        it.first_seen,
        COUNT(DISTINCT it.threat_id) as threat_count
    FROM ioc_tracking it
    WHERE it.ioc_value = ioc_val 
        AND it.ioc_type = ioc_typ
    GROUP BY it.reputation_score, it.hit_count, it.first_seen;
END;
$$ LANGUAGE plpgsql;

-- =======================
-- INITIAL DATA
-- =======================

-- Insert system configuration metrics
INSERT INTO system_metrics (metric_name, metric_value, metric_type, labels) VALUES
('database_version', 1.0, 'gauge', '{"version": "1.0", "schema": "threat_intel"}'),
('tables_created', 7, 'gauge', '{"timestamp": "' || NOW() || '"}');

-- Create default API rate limits
INSERT INTO api_rate_limits (service_name, endpoint, requests_made, requests_limit, reset_time) VALUES
('virustotal', 'ip-address/report', 0, 1000, NOW() + INTERVAL '1 day'),
('abuseipdb', 'check', 0, 1000, NOW() + INTERVAL '1 day'),
('openai', 'chat/completions', 0, 10000, NOW() + INTERVAL '1 day');

-- =======================
-- GRANTS AND PERMISSIONS
-- =======================

-- Create read-only role for reporting
CREATE ROLE threat_intel_readonly;
GRANT USAGE ON SCHEMA threat_intel TO threat_intel_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA threat_intel TO threat_intel_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA threat_intel TO threat_intel_readonly;

-- Create application role with full access
CREATE ROLE threat_intel_app;
GRANT ALL PRIVILEGES ON SCHEMA threat_intel TO threat_intel_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA threat_intel TO threat_intel_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA threat_intel TO threat_intel_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA threat_intel TO threat_intel_app;

-- Grant access to views
GRANT SELECT ON v_active_threats TO threat_intel_readonly;
GRANT SELECT ON v_ioc_intelligence TO threat_intel_readonly;
GRANT SELECT ON v_daily_threat_summary TO threat_intel_readonly;
GRANT SELECT ON v_system_health TO threat_intel_readonly;

-- Reset search path
SET search_path TO public;