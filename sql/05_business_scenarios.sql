-- STREAMFLOW | 05: Decision support: scenario modeling, NOT a causal forecast.

-- Q16: Transparent outreach discovery: historic association only.
-- "Outreach" flags identify candidates for an experiment, NOT probabilities.
WITH candidate_groups AS (
 SELECT *,
 CASE
   WHEN payment_issues = 1 AND last_login_days_ago > 90 THEN 'Payment issue + inactive >90d'
   WHEN engagement_score <= 20 THEN 'Very low engagement (<=20)'
   ELSE 'Other subscribers'
 END AS outreach_segment
 FROM streamflow.subscribers
)
SELECT outreach_segment, COUNT(*) AS subscribers,
       COUNT(*) FILTER (WHERE churned = 0) AS currently_not_churned,
       SUM(churned) AS historically_churned,
       ROUND(100.0 * AVG(churned), 2) AS observed_churn_percent
FROM candidate_groups GROUP BY outreach_segment ORDER BY observed_churn_percent DESC;

-- Q17: Hypothetical sample-wide retention improvements: nominal monthly plan value
-- of currently churned subscribers, not booked revenue, not proven achievable lift.
WITH churned_value AS (
 SELECT COUNT(*) AS churned_count, SUM(monthly_cost) AS nominal_churned_monthly_value
 FROM streamflow.subscribers WHERE churned = 1
), scenarios AS (
 SELECT unnest(ARRAY[0.01, 0.05, 0.10])::NUMERIC AS retention_improvement_fraction
)
SELECT ROUND(retention_improvement_fraction * 100, 0) AS illustrative_recovery_percent,
       ROUND(churned_count * retention_improvement_fraction, 1) AS illustrative_people_retained,
       ROUND(nominal_churned_monthly_value * retention_improvement_fraction, 2) AS monthly_plan_value_usd,
       ROUND(12 * nominal_churned_monthly_value * retention_improvement_fraction, 2) AS annualized_plan_value_usd
FROM churned_value CROSS JOIN scenarios ORDER BY illustrative_recovery_percent;

-- Q18: Separate business brief metrics from sample metrics.
-- Case facts: 2.5m subscribers, 150k monthly additions, 105k monthly losses,
-- reported $87.5m MRR; this is UNRECONCILED with the advertised plan prices.
WITH given AS (
 SELECT 2500000::NUMERIC AS total_subscribers,
        150000::NUMERIC AS monthly_new,
        105000::NUMERIC AS monthly_lost,
        87500000::NUMERIC AS reported_mrr_usd,
        19.99::NUMERIC AS highest_listed_tier_usd
)
SELECT total_subscribers, monthly_new, monthly_lost,
       (monthly_new - monthly_lost) AS monthly_net_additions,
       ROUND(100 * monthly_lost / total_subscribers, 2) AS implied_monthly_gross_churn_pct,
       ROUND(100 * (monthly_new - monthly_lost) / total_subscribers, 2) AS implied_net_growth_pct,
       ROUND(reported_mrr_usd / total_subscribers, 2) AS reported_arpu_usd,
       ROUND(total_subscribers * highest_listed_tier_usd, 2) AS maximum_tier_only_mrr_usd
FROM given;

-- Q19: Acquisition volume by signup year (not churn trend).
WITH signups AS (
 SELECT DATE_TRUNC('year', subscription_date)::DATE AS signup_year,
        COUNT(*) AS signups_in_sample
 FROM streamflow.subscribers GROUP BY 1
)
SELECT signup_year, signups_in_sample,
       LAG(signups_in_sample) OVER (ORDER BY signup_year) AS previous_sample_signups,
       ROUND(100.0 * (signups_in_sample - LAG(signups_in_sample) OVER (ORDER BY signup_year))
              / NULLIF(LAG(signups_in_sample) OVER (ORDER BY signup_year),0), 2) AS pct_change_in_sample_count
FROM signups ORDER BY signup_year;
-- Signup dates stop in May 2024; 2024 is partial and unsuitable for full-year comparison.
