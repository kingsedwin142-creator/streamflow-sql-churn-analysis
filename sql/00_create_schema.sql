-- STREAMFLOW | PostgreSQL 14+ | 00: One-time schema setup
-- Run after creating and connecting to the streamflow_portfolio database.
-- PostgreSQL is not MySQL: run in pgAdmin Query Tool or psql (NOT MySQL Workbench).
CREATE SCHEMA IF NOT EXISTS streamflow;

DROP VIEW IF EXISTS streamflow.v_retention_outreach CASCADE;
DROP VIEW IF EXISTS streamflow.v_genre_metrics CASCADE;
DROP VIEW IF EXISTS streamflow.v_region_metrics CASCADE;
DROP VIEW IF EXISTS streamflow.v_kpi_summary CASCADE;
DROP VIEW IF EXISTS streamflow.v_subscriber_enriched CASCADE;
DROP TABLE IF EXISTS streamflow.subscribers CASCADE;
DROP TABLE IF EXISTS streamflow.subscribers_raw CASCADE;
DROP TABLE IF EXISTS streamflow.dim_country_region CASCADE;

-- Small reference dimension: demonstrates a governed mapping and a real JOIN.
CREATE TABLE streamflow.dim_country_region (
    country TEXT PRIMARY KEY,
    region TEXT NOT NULL
);
INSERT INTO streamflow.dim_country_region (country, region) VALUES
    ('USA','North America'),('Canada','North America'),
    ('UK','Europe'),('Germany','Europe'),('France','Europe'),
    ('Spain','Europe'),('Italy','Europe'),('Netherlands','Europe'),
    ('Mexico','Latin America'),('Brazil','Latin America'),
    ('Argentina','Latin America'),('Colombia','Latin America'),('Chile','Latin America'),
    ('Australia','Asia-Pacific'),('South Korea','Asia-Pacific'),
    ('Japan','Asia-Pacific'),('India','Asia-Pacific'),('Singapore','Asia-Pacific');

-- Raw staging table: text-only, columns in EXACT original CSV order.
-- pgAdmin: right-click this table > Import/Export Data > Import > CSV, Header=Yes.
CREATE TABLE streamflow.subscribers_raw (
    "Subscriber_ID" TEXT,
    "Country" TEXT,
    "Age" TEXT,
    "Gender" TEXT,
    "Subscription_Date" TEXT,
    "Subscription_Tier" TEXT,
    "Monthly_Cost" TEXT,
    "Contract_Months" TEXT,
    "Months_Subscribed" TEXT,
    "Logins_Per_Month" TEXT,
    "Avg_Watch_Hours_Per_Week" TEXT,
    "Shows_Watched" TEXT,
    "Movies_Watched" TEXT,
    "Most_Watched_Genre" TEXT,
    "Downloads_Per_Month" TEXT,
    "Quality_Preference" TEXT,
    "Customer_Support_Contacts" TEXT,
    "Payment_Issues" TEXT,
    "Cancellation_Requests" TEXT,
    "Last_Login_Days_Ago" TEXT,
    "Engagement_Score" TEXT,
    "Churned" TEXT
);

-- Typed analytics layer: accessible for consistent reporting and reproducibility.
CREATE TABLE streamflow.subscribers (
    subscriber_id INTEGER PRIMARY KEY,
    country TEXT NOT NULL,
    age SMALLINT NOT NULL CHECK (age BETWEEN 0 AND 120),
    gender TEXT NOT NULL,
    subscription_date DATE NOT NULL,
    subscription_tier TEXT NOT NULL CHECK (subscription_tier IN ('Basic','Standard','Premium')),
    monthly_cost NUMERIC(8,2) NOT NULL CHECK (monthly_cost >= 0),
    contract_months SMALLINT NOT NULL CHECK (contract_months > 0),
    months_subscribed SMALLINT NOT NULL CHECK (months_subscribed >= 0),
    logins_per_month INTEGER NOT NULL CHECK (logins_per_month >= 0),
    avg_watch_hours_per_week NUMERIC(6,2) NOT NULL CHECK (avg_watch_hours_per_week >= 0),
    shows_watched INTEGER NOT NULL CHECK (shows_watched >= 0),
    movies_watched INTEGER NOT NULL CHECK (movies_watched >= 0),
    most_watched_genre TEXT NOT NULL,
    downloads_per_month INTEGER NOT NULL CHECK (downloads_per_month >= 0),
    quality_preference TEXT NOT NULL,
    customer_support_contacts SMALLINT NOT NULL CHECK (customer_support_contacts >= 0),
    payment_issues SMALLINT NOT NULL CHECK (payment_issues IN (0,1)),
    cancellation_requests SMALLINT NOT NULL CHECK (cancellation_requests >= 0),
    last_login_days_ago INTEGER NOT NULL CHECK (last_login_days_ago >= 0),
    engagement_score NUMERIC(6,2) NOT NULL CHECK (engagement_score BETWEEN 0 AND 100),
    churned SMALLINT NOT NULL CHECK (churned IN (0,1))
);
-- These indexes are illustrative. At 2,500 records sequential scans may be faster.
CREATE INDEX idx_streamflow_churn ON streamflow.subscribers (churned);
CREATE INDEX idx_streamflow_country ON streamflow.subscribers (country);
CREATE INDEX idx_streamflow_genre ON streamflow.subscribers (most_watched_genre);
