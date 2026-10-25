-- STREAMFLOW | 07: Run after SQL scripts 02-06.
-- All quality check labels below should read PASS on this supplied dataset.
SELECT 'Expected row count (2500)' AS check_name,
       CASE WHEN COUNT(*) = 2500 THEN 'PASS' ELSE 'REVIEW' END AS result
FROM streamflow.subscribers
UNION ALL
SELECT 'Unique subscriber IDs', CASE WHEN COUNT(*) = COUNT(DISTINCT subscriber_id) THEN 'PASS' ELSE 'REVIEW' END
FROM streamflow.subscribers
UNION ALL
SELECT 'Churn label restricted to 0/1', CASE WHEN COUNT(*) FILTER (WHERE churned NOT IN (0,1)) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM streamflow.subscribers
UNION ALL
SELECT 'All countries map to regions', CASE WHEN COUNT(*) FILTER (WHERE region = 'Other / unmapped') = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM streamflow.v_subscriber_enriched
UNION ALL
SELECT 'Known tier prices', CASE WHEN COUNT(*) FILTER (
 WHERE (subscription_tier='Basic' AND monthly_cost <> 9.99)
 OR (subscription_tier='Standard' AND monthly_cost <> 15.99)
 OR (subscription_tier='Premium' AND monthly_cost <> 19.99)) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM streamflow.subscribers
UNION ALL
SELECT 'Observed churn count (739)', CASE WHEN SUM(churned) = 739 THEN 'PASS' ELSE 'REVIEW' END
FROM streamflow.subscribers;

-- Sanity counts for presentation: 2500, 739, 1761, 18, 8.
SELECT COUNT(*) AS sample_size, SUM(churned) AS churned,
       COUNT(*) FILTER(WHERE churned=0) AS not_churned,
       COUNT(DISTINCT country) AS unique_countries,
       COUNT(DISTINCT most_watched_genre) AS unique_genres
FROM streamflow.subscribers;
