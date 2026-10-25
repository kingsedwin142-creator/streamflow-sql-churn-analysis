-- STREAMFLOW | 06: Reusable reporting views for a future dashboard / CSV exports.
CREATE OR REPLACE VIEW streamflow.v_kpi_summary AS
SELECT COUNT(*) AS total_subscribers, SUM(churned) AS churned,
       COUNT(*) FILTER(WHERE churned = 0) AS not_churned,
       ROUND(AVG(churned) * 100, 2) AS churn_percent,
       ROUND(SUM(monthly_cost) FILTER(WHERE churned = 0), 2) AS active_monthly_plan_value_usd,
       ROUND(SUM(monthly_cost) FILTER(WHERE churned = 1), 2) AS churned_monthly_plan_value_usd
FROM streamflow.subscribers;

CREATE OR REPLACE VIEW streamflow.v_region_metrics AS
SELECT region, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(AVG(churned) * 100, 2) AS churn_percent,
       ROUND(SUM(monthly_cost) FILTER (WHERE churned = 0), 2) AS active_monthly_plan_value_usd
FROM streamflow.v_subscriber_enriched GROUP BY region;

CREATE OR REPLACE VIEW streamflow.v_genre_metrics AS
SELECT most_watched_genre AS genre, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(AVG(churned) * 100, 2) AS churn_percent
FROM streamflow.subscribers GROUP BY most_watched_genre;

CREATE OR REPLACE VIEW streamflow.v_retention_outreach AS
SELECT subscriber_id, region, subscription_tier, monthly_cost,
       engagement_score, last_login_days_ago, payment_issues, churned,
       CASE
         WHEN payment_issues = 1 AND last_login_days_ago > 90
           THEN 'Consider payment-resolution experiment'
         WHEN engagement_score <= 20
           THEN 'Consider onboarding/discovery experiment'
         ELSE 'No rule-based flag'
       END AS experiment_flag
FROM streamflow.v_subscriber_enriched
WHERE churned = 0;

-- Query the results in pgAdmin; CSV export: right-click Query Tool results > Save Results to File.
SELECT * FROM streamflow.v_kpi_summary;
SELECT * FROM streamflow.v_region_metrics ORDER BY churn_percent DESC;
SELECT * FROM streamflow.v_genre_metrics ORDER BY churn_percent DESC;
SELECT experiment_flag, COUNT(*) AS eligible_not_churned
FROM streamflow.v_retention_outreach
GROUP BY experiment_flag ORDER BY 2 DESC;
