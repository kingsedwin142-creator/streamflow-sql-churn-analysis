-- STREAMFLOW | 08: VP OF ANALYTICS — FIVE QUESTIONS
-- Run after 00-07; figures are descriptive snapshot prevalence, NOT monthly churn or predictive scores.

-- Q1. What is the baseline churn situation in the sample?
SELECT COUNT(*) AS sample_subscribers,
       SUM(churned) AS churned,
       COUNT(*) FILTER (WHERE churned = 0) AS not_churned,
       ROUND(100.0 * AVG(churned), 2) AS observed_churn_percent
FROM streamflow.subscribers;

-- Q2. Which segments are associated with higher observed churn?
-- Mutually exclusive priority labels. This is NOT a prospective predictive model.
WITH tagged AS (
 SELECT churned, subscription_tier,
        CASE WHEN payment_issues=1 AND last_login_days_ago>90
                 THEN 'Payment issue + inactivity over 90d'
             WHEN engagement_score<=20 THEN 'Engagement score 00-20'
             ELSE 'Other' END AS priority_segment
 FROM streamflow.subscribers
)
SELECT priority_segment, COUNT(*) AS sample_subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned),2) AS observed_churn_pct
FROM tagged GROUP BY priority_segment ORDER BY observed_churn_pct DESC;

-- Q3a. Where is observed churn higher geographically?
SELECT region, COUNT(*) AS sample_subscribers, SUM(churned) AS churned,
       ROUND(100.0*AVG(churned),2) AS observed_churn_pct
FROM streamflow.v_subscriber_enriched GROUP BY region ORDER BY observed_churn_pct DESC;

-- Q3b. What does churn look like by age band?
SELECT age_band, COUNT(*) AS sample_subscribers, SUM(churned) AS churned,
       ROUND(100.0*AVG(churned),2) AS observed_churn_pct
FROM streamflow.v_subscriber_enriched GROUP BY age_band ORDER BY age_band;

-- Q4. Which content-preference genres are associated with lower observed churn?
SELECT most_watched_genre AS favorite_genre, COUNT(*) AS sample_subscribers,
       SUM(churned) AS churned, ROUND(100.0*AVG(churned),2) AS observed_churn_pct,
       ROUND(AVG(avg_watch_hours_per_week),2) AS avg_weekly_watch_hours
FROM streamflow.subscribers GROUP BY most_watched_genre ORDER BY observed_churn_pct ASC;

-- Q5. Do engagement score bands make a straightforward case for recommendations?
-- No; this is descriptive, not a recommendation-system A/B test.
SELECT engagement_band, COUNT(*) AS sample_subscribers, SUM(churned) AS churned,
       ROUND(100.0*AVG(churned),2) AS observed_churn_pct
FROM streamflow.v_subscriber_enriched GROUP BY engagement_band ORDER BY engagement_band;

-- Bonus: management growth and reported MRR consistency checks (brief inputs, NOT CSV).
SELECT 150000-105000 AS net_monthly_additions,
       ROUND(105000.0/2500000*100,2) AS implied_gross_loss_pct_of_base,
       ROUND(87500000.0/2500000,2) AS reported_revenue_per_subscriber_usd,
       ROUND(2500000*19.99,2) AS max_individual_tier_only_mrr_usd;
