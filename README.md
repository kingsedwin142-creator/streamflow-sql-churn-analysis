# StreamFlow — Subscriber Churn Analysis

**Tools:** PostgreSQL, SQL  
**Dataset:** 2,500 subscriber records

## About the project

StreamFlow is a video streaming platform that is gaining subscribers but also losing a sizeable number of them. For this project, I looked at a sample of its subscriber data to understand where churn is more common and whether viewing habits, subscription plans or payment issues tell us anything useful about retention.

The dataset covers 18 countries and includes information such as age, subscription tier, watch hours, preferred genre, engagement score and churn status.

## What I looked at

The SQL files cover data checks and cleaning, followed by comparisons of churn across subscription plans, locations, age groups and viewing behaviour. I also looked at inactivity and payment issues together to see whether they pointed to a group worth investigating further.

The analysis uses joins, `CASE` statements, aggregations, CTEs and window functions. I've kept the queries in separate files so the work is easy to follow.

## Main findings

* **Overall:** 739 out of 2,500 subscribers in the sample are marked as churned (**29.56%**).
* **Plans:** Standard has the highest observed churn (**31.84%**), compared with **27.42%** for Premium.
* **Location and age:** Europe has the highest regional figure (**30.79%**). Among the age groups, **25–34** stands out at **32.62%**.
* **Content:** Subscribers whose most-watched genre is Sports have the lowest observed churn (**24.86%**). Documentary is at **32.73%**.
* **Payment and inactivity:** Of 239 subscribers with payment issues who had not logged in for over 90 days, 91 are marked as churned (**38.08%**).


## What I took from the results

The Standard plan and the payment/inactivity group seem worth a closer look. I would start by checking whether customers are running into payment problems or not finding enough value in their plans. I'd also want to test whether better content recommendations make a difference, rather than assuming that one genre keeps people subscribed.

One thing I noticed is that churn doesn't consistently decrease as engagement scores rise. So engagement on its own isn't enough to explain the result.

**A limitation:** The churn figure here is the percentage of sample records marked as churned, **not a monthly churn rate**. The dataset doesn't include cancellation dates or detailed viewing histories, so the results show patterns rather than the causes of cancellation.

## Files

* `sql/` — PostgreSQL scripts for setup, data checks, cleaning and analysis
* `outputs/` — CSV tables containing the analysis results
* `assets/` — Charts showing some of the comparisons
* `data/` — Source subscriber dataset

### 

