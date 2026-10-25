-- STREAMFLOW | 04: Investigate WHO churns and what is ASSOCIATED with retention.
-- Cross-sectional associations are not causal evidence or validated predictions.

-- Q8: Genres; compare each genre with the sample-wide baseline.
WITH baseline AS (SELECT AVG(churned) AS baseline_rate FROM streamflow.subscribers),
 genres AS (
 SELECT most_watched_genre AS genre, COUNT(*) AS subscribers,
        SUM(churned) AS churned, AVG(churned) AS genre_rate
 FROM streamflow.subscribers GROUP BY most_watched_genre
)
SELECT genre, subscribers, churned,
       ROUND(genre_rate * 100, 2) AS churn_percent,
       ROUND((genre_rate - baseline_rate) * 100, 2) AS difference_vs_average_pp,
       DENSE_RANK() OVER (ORDER BY genre_rate ASC) AS lowest_churn_rank
FROM genres CROSS JOIN baseline ORDER BY churn_percent ASC;

-- Q9: Is stronger engagement monotonically associated with lower churn?
SELECT engagement_band, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent,
       ROUND(AVG(avg_watch_hours_per_week), 2) AS average_watch_hours
FROM streamflow.v_subscriber_enriched
GROUP BY engagement_band ORDER BY engagement_band;

-- Q10: Recency: test 0-7 days separately (do not presume a monotonic risk trend).
SELECT inactivity_band, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent,
       ROUND(AVG(engagement_score), 2) AS avg_engagement_score
FROM streamflow.v_subscriber_enriched GROUP BY inactivity_band ORDER BY inactivity_band;

-- Q11: Weekly watch time as a separate lens.
SELECT watch_band, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.v_subscriber_enriched GROUP BY watch_band ORDER BY watch_band;

-- Q12: Payment friction and customer support.
SELECT payment_issues, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.subscribers GROUP BY payment_issues ORDER BY payment_issues DESC;
SELECT customer_support_contacts, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.subscribers GROUP BY customer_support_contacts ORDER BY 1;

-- Q13: Cancellation requests can occur at unclear times relative to churn;
-- report the non-intuitive result, not a predictive claim.
SELECT cancellation_requests, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.subscribers GROUP BY cancellation_requests ORDER BY 1;

-- Q14: Average engagement for churned / not-churned segments.
SELECT churned, COUNT(*) AS subscribers,
       ROUND(AVG(engagement_score), 2) AS avg_engagement,
       ROUND(AVG(logins_per_month), 2) AS avg_logins_month,
       ROUND(AVG(avg_watch_hours_per_week), 2) AS avg_watch_hours_week,
       ROUND(AVG(last_login_days_ago), 2) AS avg_days_since_last_login,
       ROUND(AVG(months_subscribed), 2) AS avg_tenure_months
FROM streamflow.subscribers GROUP BY churned ORDER BY churned;

-- Q15: Region x plan pricing: prioritize larger segments, not noise.
WITH segments AS (
 SELECT region, subscription_tier, COUNT(*) AS subscribers,
        SUM(churned) AS churned, AVG(churned) AS churn_rate
 FROM streamflow.v_subscriber_enriched GROUP BY region, subscription_tier
)
SELECT region, subscription_tier, subscribers, churned,
       ROUND(100.0 * churn_rate, 2) AS churn_percent,
       RANK() OVER (PARTITION BY region ORDER BY churn_rate DESC) AS rank_within_region
FROM segments ORDER BY region, rank_within_region;
