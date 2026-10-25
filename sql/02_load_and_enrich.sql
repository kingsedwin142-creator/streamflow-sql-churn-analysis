-- STREAMFLOW | 02: Normalize types, then derive well-labeled analysis groups.
-- Stop and investigate if 01_profile_raw.sql produces errors, duplicates, or missing keys.
TRUNCATE TABLE streamflow.subscribers;
INSERT INTO streamflow.subscribers (
    subscriber_id, country, age, gender, subscription_date, subscription_tier,
    monthly_cost, contract_months, months_subscribed, logins_per_month,
    avg_watch_hours_per_week, shows_watched, movies_watched, most_watched_genre,
    downloads_per_month, quality_preference, customer_support_contacts,
    payment_issues, cancellation_requests, last_login_days_ago, engagement_score, churned
)
SELECT
    BTRIM("Subscriber_ID")::INTEGER,
    BTRIM("Country"),
    BTRIM("Age")::SMALLINT,
    INITCAP(BTRIM("Gender")),
    BTRIM("Subscription_Date")::DATE,
    INITCAP(BTRIM("Subscription_Tier")),
    BTRIM("Monthly_Cost")::NUMERIC(8,2),
    BTRIM("Contract_Months")::SMALLINT,
    BTRIM("Months_Subscribed")::SMALLINT,
    BTRIM("Logins_Per_Month")::INTEGER,
    BTRIM("Avg_Watch_Hours_Per_Week")::NUMERIC(6,2),
    BTRIM("Shows_Watched")::INTEGER,
    BTRIM("Movies_Watched")::INTEGER,
    BTRIM("Most_Watched_Genre"),
    BTRIM("Downloads_Per_Month")::INTEGER,
    BTRIM("Quality_Preference"),
    BTRIM("Customer_Support_Contacts")::SMALLINT,
    BTRIM("Payment_Issues")::SMALLINT,
    BTRIM("Cancellation_Requests")::SMALLINT,
    BTRIM("Last_Login_Days_Ago")::INTEGER,
    BTRIM("Engagement_Score")::NUMERIC(6,2),
    BTRIM("Churned")::SMALLINT
FROM streamflow.subscribers_raw;

CREATE OR REPLACE VIEW streamflow.v_subscriber_enriched AS
SELECT s.*,
       COALESCE(geo.region, 'Other / unmapped') AS region,
       CASE
         WHEN age < 25 THEN '16-24'
         WHEN age < 35 THEN '25-34'
         WHEN age < 45 THEN '35-44'
         WHEN age < 55 THEN '45-54'
         WHEN age < 65 THEN '55-64'
         ELSE '65+'
       END AS age_band,
       CASE
         WHEN engagement_score <= 20 THEN '00-20'
         WHEN engagement_score <= 40 THEN '21-40'
         WHEN engagement_score <= 60 THEN '41-60'
         WHEN engagement_score <= 80 THEN '61-80'
         ELSE '81-100'
       END AS engagement_band,
       CASE
         WHEN last_login_days_ago <= 7 THEN '00-07 days'
         WHEN last_login_days_ago <= 30 THEN '08-30 days'
         WHEN last_login_days_ago <= 60 THEN '31-60 days'
         WHEN last_login_days_ago <= 90 THEN '61-90 days'
         ELSE '91+ days'
       END AS inactivity_band,
       CASE
         WHEN months_subscribed <= 3 THEN '01-03 months'
         WHEN months_subscribed <= 6 THEN '04-06 months'
         WHEN months_subscribed <= 12 THEN '07-12 months'
         WHEN months_subscribed <= 24 THEN '13-24 months'
         ELSE '25+ months'
       END AS tenure_band,
       CASE
         WHEN avg_watch_hours_per_week <= 2 THEN '00-02 hours'
         WHEN avg_watch_hours_per_week <= 5 THEN '02-05 hours'
         WHEN avg_watch_hours_per_week <= 10 THEN '05-10 hours'
         ELSE '10+ hours'
       END AS watch_band
FROM streamflow.subscribers s
LEFT JOIN streamflow.dim_country_region geo ON s.country = geo.country;

-- Expected: 2,500 rows. Region should contain no "Other / unmapped" records.
SELECT COUNT(*) AS cleaned_rows,
       COUNT(DISTINCT subscriber_id) AS unique_subscribers,
       COUNT(*) FILTER (WHERE region = 'Other / unmapped') AS unmapped_countries
FROM streamflow.v_subscriber_enriched;
