-- STREAMFLOW | 01: Run AFTER importing the CSV, BEFORE cleaning.
-- 01a. Dataset size and distinct subscriber identifiers (expected: 2,500 each).
SELECT COUNT(*) AS source_rows,
       COUNT(DISTINCT "Subscriber_ID") AS distinct_subscriber_ids
FROM streamflow.subscribers_raw;

-- 01b. Blanks/nulls across EVERY column (expected: zero for this file).
SELECT column_name, COUNT(*) AS missing_or_blank
FROM streamflow.subscribers_raw r
CROSS JOIN LATERAL jsonb_each_text(to_jsonb(r)) AS field(column_name, field_value)
WHERE field_value IS NULL OR BTRIM(field_value) = ''
GROUP BY column_name ORDER BY missing_or_blank DESC, column_name;

-- 01c. Duplicate business keys (expected: no records).
SELECT "Subscriber_ID", COUNT(*) AS repeats
FROM streamflow.subscribers_raw
GROUP BY "Subscriber_ID" HAVING COUNT(*) > 1
ORDER BY repeats DESC;

-- 01d. Invalid numeric formats (expected: all zero).
SELECT
 COUNT(*) FILTER (WHERE "Subscriber_ID" !~ '^[0-9]+$') AS invalid_ids,
 COUNT(*) FILTER (WHERE "Age" !~ '^[0-9]+$') AS invalid_ages,
 COUNT(*) FILTER (WHERE "Monthly_Cost" !~ '^[0-9]+(\.[0-9]+)?$') AS invalid_costs,
 COUNT(*) FILTER (WHERE "Churned" NOT IN ('0','1')) AS invalid_churn_values
FROM streamflow.subscribers_raw;

-- 01e. Tier-to-price reconciliation (expected Basic=9.99, Standard=15.99, Premium=19.99).
SELECT "Subscription_Tier", "Monthly_Cost", COUNT(*) AS subscribers
FROM streamflow.subscribers_raw
GROUP BY 1,2 ORDER BY 1,2;

-- 01f. Coverage and observation range.
SELECT COUNT(DISTINCT "Country") AS countries_in_sample,
       COUNT(DISTINCT "Most_Watched_Genre") AS genres_in_sample,
       MIN("Subscription_Date") AS earliest_signup,
       MAX("Subscription_Date") AS latest_signup
FROM streamflow.subscribers_raw;
