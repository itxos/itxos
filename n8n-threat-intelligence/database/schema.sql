-- AI-Powered Threat Intelligence System Database Schema
-- PostgreSQL Database Schema for storing threat intelligence data

-- Create database (run this as superuser)
-- CREATE DATABASE threat_intelligence;

-- Create user (run this as superuser)
-- CREATE USER ti_user WITH PASSWORD 'your_secure_password_here';

-- Grant privileges (run this as superuser)
-- GRANT ALL PRIVILEGES ON DATABASE threat_intelligence TO ti_user;

-- Connect to the database and create tables
\c threat_intelligence;

-- Enable UUID extension for generating unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types for threat levels and IOC types
CREATE TYPE threat_level_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
CREATE TYPE ioc_type_enum AS ENUM ('ipv4-addr', 'ipv6-addr', 'domain-name', 'url', 'file', 'email-addr', 'mutex', 'registry-key');
CREATE TYPE processing_status_enum AS ENUM ('received', 'processing', 'enriched', 'analyzed', 'alerted', 'completed', 'failed');

-- Main threat intelligence table
CREATE TABLE threat_intelligence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ioc_type ioc_type_enum NOT NULL,
    ioc_value TEXT NOT NULL,
    threat_score INTEGER CHECK (threat_score >= 0 AND threat_score <= 100),
    threat_level threat_level_enum,
    confidence INTEGER CHECK (confidence >= 0 AND confidence <= 100),
    risk_factors JSONB,
    indicators TEXT[],
    enrichment_data JSONB,
    ai_summary TEXT,
    source TEXT NOT NULL,
    raw_data JSONB,
    processing_status processing_status_enum DEFAULT 'received',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '90 days'),
    is_false_positive BOOLEAN DEFAULT FALSE,
    analyst_notes TEXT,
    
    -- Create indexes for performance
    CONSTRAINT unique_ioc_source UNIQUE (ioc_value, source, created_at)
);

-- Create indexes for better query performance
CREATE INDEX idx_threat_intelligence_ioc_value ON threat_intelligence (ioc_value);
CREATE INDEX idx_threat_intelligence_ioc_type ON threat_intelligence (ioc_type);
CREATE INDEX idx_threat_intelligence_threat_level ON threat_intelligence (threat_level);
CREATE INDEX idx_threat_intelligence_threat_score ON threat_intelligence (threat_score DESC);
CREATE INDEX idx_threat_intelligence_created_at ON threat_intelligence (created_at DESC);
CREATE INDEX idx_threat_intelligence_source ON threat_intelligence (source);
CREATE INDEX idx_threat_intelligence_status ON threat_intelligence (processing_status);
CREATE INDEX idx_threat_intelligence_expires_at ON threat_intelligence (expires_at);

-- GIN indexes for JSONB columns for better performance on JSON queries
CREATE INDEX idx_threat_intelligence_enrichment_gin ON threat_intelligence USING GIN (enrichment_data);
CREATE INDEX idx_threat_intelligence_risk_factors_gin ON threat_intelligence USING GIN (risk_factors);

-- Enrichment sources tracking table
CREATE TABLE enrichment_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    threat_intelligence_id UUID REFERENCES threat_intelligence(id) ON DELETE CASCADE,
    source_name TEXT NOT NULL,
    source_data JSONB,
    confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
    retrieved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    api_response_time_ms INTEGER,
    is_successful BOOLEAN DEFAULT TRUE,
    error_message TEXT
);

CREATE INDEX idx_enrichment_sources_ti_id ON enrichment_sources (threat_intelligence_id);
CREATE INDEX idx_enrichment_sources_name ON enrichment_sources (source_name);
CREATE INDEX idx_enrichment_sources_retrieved_at ON enrichment_sources (retrieved_at DESC);

-- Alerts tracking table
CREATE TABLE threat_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    threat_intelligence_id UUID REFERENCES threat_intelligence(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL, -- 'slack', 'email', 'webhook'
    alert_channel TEXT, -- channel name, email address, webhook URL
    alert_status TEXT DEFAULT 'sent', -- 'sent', 'failed', 'acknowledged'
    alert_content TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by TEXT,
    error_message TEXT
);

CREATE INDEX idx_threat_alerts_ti_id ON threat_alerts (threat_intelligence_id);
CREATE INDEX idx_threat_alerts_type ON threat_alerts (alert_type);
CREATE INDEX idx_threat_alerts_status ON threat_alerts (alert_status);
CREATE INDEX idx_threat_alerts_sent_at ON threat_alerts (sent_at DESC);

-- IOC relationships table (for tracking related IOCs)
CREATE TABLE ioc_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_ioc_id UUID REFERENCES threat_intelligence(id) ON DELETE CASCADE,
    related_ioc_id UUID REFERENCES threat_intelligence(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL, -- 'resolved_to', 'communicates_with', 'drops', 'contains'
    confidence INTEGER CHECK (confidence >= 0 AND confidence <= 100) DEFAULT 50,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT no_self_reference CHECK (parent_ioc_id != related_ioc_id),
    CONSTRAINT unique_relationship UNIQUE (parent_ioc_id, related_ioc_id, relationship_type)
);

CREATE INDEX idx_ioc_relationships_parent ON ioc_relationships (parent_ioc_id);
CREATE INDEX idx_ioc_relationships_related ON ioc_relationships (related_ioc_id);
CREATE INDEX idx_ioc_relationships_type ON ioc_relationships (relationship_type);

-- Workflow execution logs table
CREATE TABLE workflow_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id TEXT NOT NULL,
    execution_id TEXT NOT NULL,
    status TEXT NOT NULL, -- 'running', 'success', 'error', 'cancelled'
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,
    processed_items INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    error_details JSONB,
    execution_data JSONB,
    
    CONSTRAINT unique_execution UNIQUE (workflow_id, execution_id)
);

CREATE INDEX idx_workflow_executions_workflow_id ON workflow_executions (workflow_id);
CREATE INDEX idx_workflow_executions_status ON workflow_executions (status);
CREATE INDEX idx_workflow_executions_start_time ON workflow_executions (start_time DESC);

-- API rate limiting table
CREATE TABLE api_rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name TEXT NOT NULL,
    api_key_hash TEXT, -- Hashed API key for tracking usage per key
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    window_end TIMESTAMP WITH TIME ZONE,
    limit_exceeded_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_service_window UNIQUE (service_name, api_key_hash, window_start)
);

CREATE INDEX idx_api_rate_limits_service ON api_rate_limits (service_name);
CREATE INDEX idx_api_rate_limits_window ON api_rate_limits (window_start, window_end);

-- Threat intelligence metrics for dashboard
CREATE TABLE ti_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_date DATE DEFAULT CURRENT_DATE,
    total_iocs INTEGER DEFAULT 0,
    new_iocs INTEGER DEFAULT 0,
    high_threat_iocs INTEGER DEFAULT 0,
    critical_threat_iocs INTEGER DEFAULT 0,
    false_positives INTEGER DEFAULT 0,
    alerts_sent INTEGER DEFAULT 0,
    avg_processing_time_ms INTEGER DEFAULT 0,
    top_sources JSONB,
    top_ioc_types JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_metric_date UNIQUE (metric_date)
);

CREATE INDEX idx_ti_metrics_date ON ti_metrics (metric_date DESC);

-- Create functions and triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update the updated_at column
CREATE TRIGGER update_threat_intelligence_updated_at 
    BEFORE UPDATE ON threat_intelligence 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up expired IOCs
CREATE OR REPLACE FUNCTION cleanup_expired_iocs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM threat_intelligence 
    WHERE expires_at < CURRENT_TIMESTAMP 
    AND is_false_positive = FALSE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    INSERT INTO workflow_executions (workflow_id, execution_id, status, start_time, end_time, processed_items)
    VALUES ('cleanup_expired_iocs', uuid_generate_v4()::text, 'success', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, deleted_count);
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to update daily metrics
CREATE OR REPLACE FUNCTION update_daily_metrics()
RETURNS VOID AS $$
DECLARE
    metric_date DATE := CURRENT_DATE;
    total_count INTEGER;
    new_count INTEGER;
    high_count INTEGER;
    critical_count INTEGER;
    fp_count INTEGER;
    alert_count INTEGER;
    avg_processing INTEGER;
    top_src JSONB;
    top_types JSONB;
BEGIN
    -- Calculate metrics
    SELECT COUNT(*) INTO total_count FROM threat_intelligence WHERE DATE(created_at) = metric_date;
    SELECT COUNT(*) INTO new_count FROM threat_intelligence WHERE DATE(created_at) = metric_date;
    SELECT COUNT(*) INTO high_count FROM threat_intelligence WHERE DATE(created_at) = metric_date AND threat_level = 'HIGH';
    SELECT COUNT(*) INTO critical_count FROM threat_intelligence WHERE DATE(created_at) = metric_date AND threat_level = 'CRITICAL';
    SELECT COUNT(*) INTO fp_count FROM threat_intelligence WHERE DATE(created_at) = metric_date AND is_false_positive = TRUE;
    SELECT COUNT(*) INTO alert_count FROM threat_alerts WHERE DATE(sent_at) = metric_date;
    
    -- Calculate average processing time (mock calculation)
    SELECT COALESCE(AVG(1000), 0)::INTEGER INTO avg_processing FROM threat_intelligence WHERE DATE(created_at) = metric_date;
    
    -- Get top sources
    SELECT json_object_agg(source, cnt) INTO top_src FROM (
        SELECT source, COUNT(*) as cnt 
        FROM threat_intelligence 
        WHERE DATE(created_at) = metric_date 
        GROUP BY source 
        ORDER BY cnt DESC 
        LIMIT 10
    ) t;
    
    -- Get top IOC types
    SELECT json_object_agg(ioc_type, cnt) INTO top_types FROM (
        SELECT ioc_type, COUNT(*) as cnt 
        FROM threat_intelligence 
        WHERE DATE(created_at) = metric_date 
        GROUP BY ioc_type 
        ORDER BY cnt DESC
    ) t;
    
    -- Insert or update metrics
    INSERT INTO ti_metrics (metric_date, total_iocs, new_iocs, high_threat_iocs, critical_threat_iocs, 
                           false_positives, alerts_sent, avg_processing_time_ms, top_sources, top_ioc_types)
    VALUES (metric_date, total_count, new_count, high_count, critical_count, fp_count, alert_count, 
            avg_processing, top_src, top_types)
    ON CONFLICT (metric_date) 
    DO UPDATE SET 
        total_iocs = EXCLUDED.total_iocs,
        new_iocs = EXCLUDED.new_iocs,
        high_threat_iocs = EXCLUDED.high_threat_iocs,
        critical_threat_iocs = EXCLUDED.critical_threat_iocs,
        false_positives = EXCLUDED.false_positives,
        alerts_sent = EXCLUDED.alerts_sent,
        avg_processing_time_ms = EXCLUDED.avg_processing_time_ms,
        top_sources = EXCLUDED.top_sources,
        top_ioc_types = EXCLUDED.top_ioc_types;
END;
$$ LANGUAGE plpgsql;

-- Create views for common queries
CREATE VIEW high_threat_iocs AS
SELECT 
    id,
    ioc_type,
    ioc_value,
    threat_score,
    threat_level,
    confidence,
    source,
    created_at,
    ai_summary
FROM threat_intelligence 
WHERE threat_level IN ('HIGH', 'CRITICAL') 
AND is_false_positive = FALSE 
AND expires_at > CURRENT_TIMESTAMP
ORDER BY threat_score DESC, created_at DESC;

CREATE VIEW recent_alerts AS
SELECT 
    ta.id,
    ti.ioc_value,
    ti.ioc_type,
    ti.threat_level,
    ti.threat_score,
    ta.alert_type,
    ta.alert_status,
    ta.sent_at,
    ta.acknowledged_at
FROM threat_alerts ta
JOIN threat_intelligence ti ON ta.threat_intelligence_id = ti.id
WHERE ta.sent_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
ORDER BY ta.sent_at DESC;

CREATE VIEW enrichment_summary AS
SELECT 
    ti.id,
    ti.ioc_value,
    ti.ioc_type,
    COUNT(es.id) as enrichment_count,
    AVG(es.confidence_score) as avg_confidence,
    AVG(es.api_response_time_ms) as avg_response_time,
    array_agg(DISTINCT es.source_name) as sources
FROM threat_intelligence ti
LEFT JOIN enrichment_sources es ON ti.id = es.threat_intelligence_id
GROUP BY ti.id, ti.ioc_value, ti.ioc_type;

-- Grant permissions to the ti_user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ti_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ti_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ti_user;

-- Create indexes on views (if supported by your PostgreSQL version)
-- These are materialized view indexes for better performance
-- Uncomment if you want to use materialized views instead

-- CREATE MATERIALIZED VIEW high_threat_iocs_mv AS SELECT * FROM high_threat_iocs;
-- CREATE INDEX idx_high_threat_iocs_mv_score ON high_threat_iocs_mv (threat_score DESC);
-- CREATE INDEX idx_high_threat_iocs_mv_created ON high_threat_iocs_mv (created_at DESC);

-- Sample data for testing (optional)
/*
INSERT INTO threat_intelligence (ioc_type, ioc_value, threat_score, threat_level, confidence, source, raw_data)
VALUES 
    ('ipv4-addr', '192.168.1.100', 85, 'HIGH', 95, 'manual_analysis', '{"test": true}'),
    ('domain-name', 'malicious-domain.com', 92, 'CRITICAL', 88, 'threat_feed', '{"test": true}'),
    ('file', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 45, 'MEDIUM', 70, 'sandbox_analysis', '{"test": true}');
*/

-- Performance optimization settings (add to postgresql.conf)
/*
# Recommended PostgreSQL configuration for threat intelligence workload
shared_preload_libraries = 'pg_stat_statements'
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 8MB
*/

COMMENT ON DATABASE threat_intelligence IS 'AI-Powered Threat Intelligence System Database';
COMMENT ON TABLE threat_intelligence IS 'Main table storing threat intelligence indicators and analysis results';
COMMENT ON TABLE enrichment_sources IS 'Tracks data from various threat intelligence sources';
COMMENT ON TABLE threat_alerts IS 'Logs all alerts sent for threat indicators';
COMMENT ON TABLE ioc_relationships IS 'Stores relationships between different IOCs';
COMMENT ON TABLE workflow_executions IS 'Tracks n8n workflow execution history and performance';
COMMENT ON TABLE api_rate_limits IS 'Manages API rate limiting across different services';
COMMENT ON TABLE ti_metrics IS 'Daily aggregated metrics for dashboards and reporting';