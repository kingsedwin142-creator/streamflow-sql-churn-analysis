-- STREAMFLOW | 03: Core analytics. Every metric is a SNAPSHOT, not monthly churn.

-- Q1: How many subscribers have churned, and how much nominal monthly-plan value is involved?
SELECT COUNT(*) AS sample_subscribers,
       COUNT(*) FILTER (WHERE churned = 1) AS churned_subscribers,
       COUNT(*) FILTER (WHERE churned = 0) AS not_churned_subscribers,
       ROUND(100.0 * AVG(churned), 2) AS observed_churn_percent,
       ROUND(SUM(monthly_cost), 2) AS nominal_monthly_fees_all_sample_usd,
       ROUND(SUM(monthly_cost) FILTER (WHERE churned = 0), 2) AS active_plan_value_usd,
       ROUND(SUM(monthly_cost) FILTER (WHERE churned = 1), 2) AS churned_plan_value_usd
FROM streamflow.subscribers;

-- Q2: Which pricing tier has the highest observed churn?
SELECT subscription_tier,
       COUNT(*) AS subscribers,
       SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent,
       ROUND(SUM(monthly_cost) FILTER (WHERE churned = 0), 2) AS active_plan_value_usd
FROM streamflow.subscribers GROUP BY subscription_tier
ORDER BY churn_percent DESC;

-- Q3: Which regions appear different? Small groups must be interpreted cautiously.
SELECT region, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent,
       ROUND(SUM(monthly_cost) FILTER (WHERE churned = 0), 2) AS active_plan_value_usd
FROM streamflow.v_subscriber_enriched GROUP BY region
ORDER BY churn_percent DESC;

-- Q4: Countries. Window function ranks only sample-size-eligible countries.
WITH per_country AS (
 SELECT region, country, COUNT(*) AS subscribers, SUM(churned) AS churned,
        ROUND(100.0 * AVG(churned), 2) AS churn_percent
 FROM streamflow.v_subscriber_enriched GROUP BY region, country
)
SELECT DENSE_RANK() OVER (ORDER BY churn_percent DESC) AS churn_rank,
       region, country, subscribers, churned, churn_percent
FROM per_country WHERE subscribers >= 30
ORDER BY churn_rank, country;

-- Q5: Which age bands are worth further investigation?
SELECT age_band, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.v_subscriber_enriched GROUP BY age_band
ORDER BY age_band;

-- Q6: Compare contract duration and tenure.
SELECT contract_months, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.subscribers GROUP BY contract_months ORDER BY contract_months;
SELECT tenure_band, COUNT(*) AS subscribers, SUM(churned) AS churned,
       ROUND(100.0 * AVG(churned), 2) AS churn_percent
FROM streamflow.v_subscriber_enriched GROUP BY tenure_band ORDER BY tenure_band;

-- Q7: Sign-up cohorts. IMPORTANT: this is signup-year composition and SNAPSHOT
-- churn proportion, not a month-by-month retention curve.
SELECT EXTRACT(YEAR FROM subscription_date)::INTEGER AS signup_year,
       COUNT(*) AS acquired_in_sample,
       SUM(churned) AS ever_labeled_churned,
       ROUND(100.0 * AVG(churned), 2) AS observed_churn_percent
FROM streamflow.subscribers GROUP BY 1 ORDER BY 1;
