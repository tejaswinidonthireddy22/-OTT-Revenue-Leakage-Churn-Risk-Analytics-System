-- =============================================================================
-- OTT Revenue Leakage & Churn Risk Analytics System
-- SQL Analytics Queries
-- =============================================================================
-- Database : SQLite / PostgreSQL (ANSI SQL Compatible)
-- Tables   : users, payments, subscriptions, discounts, events
-- Author   : Analytics Team
-- =============================================================================

-- =============================================================================
-- SECTION 0: TABLE CREATION & SCHEMA
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    user_id           INTEGER PRIMARY KEY,
    name              VARCHAR(100),
    age               INTEGER,
    country           VARCHAR(50),
    subscription_type VARCHAR(20),   -- Basic / Standard / Premium
    watch_time_hours  DECIMAL(8,2),
    favorite_genre    VARCHAR(50),
    last_login        DATE
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id        INTEGER PRIMARY KEY,
    user_id           INTEGER REFERENCES users(user_id),
    billing_date      DATE,
    plan_price        DECIMAL(10,2),
    payment_method    VARCHAR(30),   -- Credit Card / Debit Card / Wallet / UPI / Net Banking
    payment_status    VARCHAR(10),   -- Success / Failed
    auto_renewal      VARCHAR(3),    -- Yes / No
    retry_attempts    INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS discounts (
    discount_id       INTEGER PRIMARY KEY,
    user_id           INTEGER,
    discount_type     VARCHAR(20),   -- None / 10% / 20% / Free Trial
    free_trial_used   BOOLEAN DEFAULT FALSE,
    refund_issued     BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS subscription_events (
    event_id          INTEGER PRIMARY KEY,
    user_id           INTEGER,
    event_type        VARCHAR(30),   -- Upgrade / Downgrade / Cancel / Renew
    event_date        DATE,
    old_plan          VARCHAR(20),
    new_plan          VARCHAR(20),
    days_before_billing INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


-- =============================================================================
-- SECTION 1: REVENUE LEAKAGE KPIs
-- =============================================================================

-- 1.1 Overall Revenue Leakage Rate
SELECT
    COUNT(*)                                                   AS total_billing_attempts,
    SUM(plan_price)                                            AS total_possible_revenue,
    SUM(CASE WHEN payment_status = 'Success' THEN plan_price ELSE 0 END) AS revenue_earned,
    SUM(CASE WHEN payment_status = 'Failed'  THEN plan_price ELSE 0 END) AS revenue_at_risk,
    ROUND(
        SUM(CASE WHEN payment_status = 'Failed' THEN plan_price ELSE 0 END)
        / NULLIF(SUM(plan_price), 0) * 100, 2
    )                                                          AS leakage_rate_pct
FROM payments;


-- 1.2 Monthly Revenue Leakage Trend
SELECT
    DATE_TRUNC('month', billing_date)                          AS billing_month,
    SUM(plan_price)                                            AS total_revenue,
    SUM(CASE WHEN payment_status = 'Failed' THEN plan_price ELSE 0 END) AS revenue_lost,
    ROUND(
        SUM(CASE WHEN payment_status = 'Failed' THEN plan_price ELSE 0 END)
        / NULLIF(SUM(plan_price), 0) * 100, 2
    )                                                          AS monthly_leakage_pct
FROM payments
GROUP BY DATE_TRUNC('month', billing_date)
ORDER BY billing_month DESC;


-- 1.3 Revenue At Risk by Subscription Plan
SELECT
    u.subscription_type,
    COUNT(DISTINCT p.user_id)                                  AS affected_users,
    SUM(p.plan_price)                                          AS total_billed,
    SUM(CASE WHEN p.payment_status = 'Failed' THEN p.plan_price ELSE 0 END) AS revenue_at_risk,
    ROUND(
        SUM(CASE WHEN p.payment_status = 'Failed' THEN p.plan_price ELSE 0 END)
        / NULLIF(SUM(p.plan_price), 0) * 100, 2
    )                                                          AS leakage_pct
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY u.subscription_type
ORDER BY revenue_at_risk DESC;


-- =============================================================================
-- SECTION 2: PAYMENT FAILURE ANALYSIS
-- =============================================================================

-- 2.1 Payment Failure Rate by Method
SELECT
    payment_method,
    COUNT(*)                                                   AS total_transactions,
    SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END) AS failed_count,
    ROUND(
        SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                          AS failure_rate_pct,
    SUM(CASE WHEN payment_status = 'Failed' THEN plan_price ELSE 0 END) AS revenue_lost
FROM payments
GROUP BY payment_method
ORDER BY failure_rate_pct DESC;


-- 2.2 Failed Payments with Retry Analysis
SELECT
    payment_method,
    AVG(retry_attempts)                                        AS avg_retries,
    SUM(CASE WHEN retry_attempts = 0 AND payment_status = 'Failed' THEN 1 ELSE 0 END) AS no_retry_failures,
    SUM(CASE WHEN retry_attempts >= 1 AND payment_status = 'Failed' THEN 1 ELSE 0 END) AS retried_still_failed,
    SUM(CASE WHEN retry_attempts >= 1 AND payment_status = 'Success' THEN 1 ELSE 0 END) AS retried_recovered
FROM payments
WHERE payment_status = 'Failed' OR retry_attempts > 0
GROUP BY payment_method
ORDER BY avg_retries DESC;


-- 2.3 Auto-Renewal Success Rate
SELECT
    u.subscription_type,
    COUNT(*)                                                   AS total_users,
    SUM(CASE WHEN p.auto_renewal = 'Yes' THEN 1 ELSE 0 END)   AS auto_renewal_enabled,
    ROUND(
        SUM(CASE WHEN p.auto_renewal = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                          AS auto_renewal_rate_pct,
    SUM(CASE WHEN p.auto_renewal = 'No' AND p.payment_status = 'Failed' THEN p.plan_price ELSE 0 END)
                                                               AS revenue_lost_no_renewal
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY u.subscription_type
ORDER BY auto_renewal_rate_pct ASC;


-- =============================================================================
-- SECTION 3: ARPU & CUSTOMER LIFETIME VALUE
-- =============================================================================

-- 3.1 Average Revenue Per User (ARPU) by Plan
SELECT
    u.subscription_type,
    COUNT(DISTINCT p.user_id)                                  AS paying_users,
    ROUND(AVG(p.plan_price), 2)                                AS plan_price,
    ROUND(
        SUM(CASE WHEN p.payment_status = 'Success' THEN p.plan_price ELSE 0 END)
        / NULLIF(COUNT(DISTINCT p.user_id), 0), 2
    )                                                          AS actual_arpu,
    ROUND(
        SUM(p.plan_price) / NULLIF(COUNT(DISTINCT p.user_id), 0), 2
    )                                                          AS expected_arpu,
    ROUND(
        (1 - SUM(CASE WHEN p.payment_status = 'Success' THEN p.plan_price ELSE 0 END)
        / NULLIF(SUM(p.plan_price), 0)) * 100, 2
    )                                                          AS arpu_gap_pct
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY u.subscription_type
ORDER BY actual_arpu DESC;


-- 3.2 Customer Lifetime Value (CLV) – Simplified
WITH monthly_arpu AS (
    SELECT
        p.user_id,
        u.subscription_type,
        u.country,
        AVG(p.plan_price)                                      AS monthly_arpu,
        MIN(p.billing_date)                                    AS first_billing,
        MAX(p.billing_date)                                    AS last_billing,
        DATEDIFF('month', MIN(p.billing_date), MAX(p.billing_date)) + 1 AS tenure_months
    FROM payments p
    JOIN users u ON p.user_id = u.user_id
    WHERE p.payment_status = 'Success'
    GROUP BY p.user_id, u.subscription_type, u.country
)
SELECT
    subscription_type,
    country,
    ROUND(AVG(monthly_arpu), 2)                                AS avg_monthly_arpu,
    ROUND(AVG(tenure_months), 1)                               AS avg_tenure_months,
    ROUND(AVG(monthly_arpu) * AVG(tenure_months), 2)           AS avg_clv,
    ROUND(AVG(monthly_arpu) * 24, 2)                           AS projected_2yr_clv
FROM monthly_arpu
GROUP BY subscription_type, country
ORDER BY avg_clv DESC
LIMIT 20;


-- =============================================================================
-- SECTION 4: DISCOUNT & FREE TRIAL ABUSE
-- =============================================================================

-- 4.1 Revenue Impact of Discount Types
SELECT
    d.discount_type,
    COUNT(DISTINCT d.user_id)                                  AS users_with_discount,
    ROUND(AVG(p.plan_price), 2)                                AS avg_plan_price,
    ROUND(
        SUM(CASE WHEN p.payment_status = 'Success' THEN p.plan_price ELSE 0 END)
        / NULLIF(COUNT(DISTINCT d.user_id), 0), 2
    )                                                          AS actual_arpu,
    SUM(CASE WHEN p.payment_status = 'Failed' THEN p.plan_price ELSE 0 END) AS revenue_at_risk
FROM discounts d
JOIN payments p ON d.user_id = p.user_id
GROUP BY d.discount_type
ORDER BY actual_arpu ASC;


-- 4.2 Free Trial Abuse Detection
SELECT
    d.user_id,
    u.name,
    u.country,
    u.subscription_type,
    d.free_trial_used,
    d.refund_issued,
    p.payment_status,
    p.auto_renewal,
    u.watch_time_hours
FROM discounts d
JOIN users u ON d.user_id = u.user_id
JOIN payments p ON d.user_id = p.user_id
WHERE d.free_trial_used = TRUE
  AND (p.payment_status = 'Failed' OR d.refund_issued = TRUE)
ORDER BY u.watch_time_hours ASC
LIMIT 50;


-- 4.3 Refund Abuse Rate
SELECT
    u.subscription_type,
    COUNT(DISTINCT d.user_id)                                  AS total_users,
    SUM(CASE WHEN d.refund_issued = TRUE THEN 1 ELSE 0 END)    AS refund_count,
    ROUND(
        SUM(CASE WHEN d.refund_issued = TRUE THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(DISTINCT d.user_id), 0), 2
    )                                                          AS refund_rate_pct
FROM discounts d
JOIN users u ON d.user_id = u.user_id
GROUP BY u.subscription_type
ORDER BY refund_rate_pct DESC;


-- =============================================================================
-- SECTION 5: CHURN RISK SEGMENTATION
-- =============================================================================

-- 5.1 High Churn Risk Users
SELECT
    u.user_id,
    u.name,
    u.country,
    u.subscription_type,
    u.watch_time_hours,
    CURRENT_DATE - u.last_login                                AS days_since_login,
    p.payment_status,
    p.auto_renewal,
    CASE
        WHEN (CURRENT_DATE - u.last_login) > 90 AND u.watch_time_hours < 50 THEN 'High'
        WHEN (CURRENT_DATE - u.last_login) > 60 OR u.watch_time_hours < 100  THEN 'Medium'
        ELSE 'Low'
    END                                                        AS churn_risk_label
FROM users u
LEFT JOIN payments p ON u.user_id = p.user_id
ORDER BY days_since_login DESC, watch_time_hours ASC;


-- 5.2 Churn Risk Summary
SELECT
    churn_risk_label,
    COUNT(*)                                                   AS user_count,
    ROUND(AVG(watch_time_hours), 1)                            AS avg_watch_hours,
    ROUND(AVG(days_since_login), 0)                            AS avg_days_inactive
FROM (
    SELECT
        u.user_id,
        u.watch_time_hours,
        CURRENT_DATE - u.last_login                            AS days_since_login,
        CASE
            WHEN (CURRENT_DATE - u.last_login) > 90 AND u.watch_time_hours < 50 THEN 'High'
            WHEN (CURRENT_DATE - u.last_login) > 60 OR u.watch_time_hours < 100 THEN 'Medium'
            ELSE 'Low'
        END                                                    AS churn_risk_label
    FROM users u
) churn_base
GROUP BY churn_risk_label
ORDER BY
    CASE churn_risk_label WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;


-- =============================================================================
-- SECTION 6: PLAN DOWNGRADE ANALYSIS
-- =============================================================================

-- 6.1 Plan Downgrade Events Before Billing
SELECT
    e.old_plan,
    e.new_plan,
    COUNT(*)                                                   AS downgrade_count,
    AVG(e.days_before_billing)                                 AS avg_days_before_billing,
    SUM(p.plan_price - p2.plan_price)                          AS estimated_revenue_lost
FROM subscription_events e
JOIN users u ON e.user_id = u.user_id
JOIN payments p  ON u.user_id = p.user_id AND p.billing_date >= e.event_date
LEFT JOIN payments p2 ON p.user_id = p2.user_id AND p2.billing_date < e.event_date
WHERE e.event_type = 'Downgrade'
GROUP BY e.old_plan, e.new_plan
ORDER BY downgrade_count DESC;


-- =============================================================================
-- SECTION 7: RECOVERY OPPORTUNITY
-- =============================================================================

-- 7.1 Estimated Recovery if Retry Strategy Applied
SELECT
    payment_method,
    SUM(CASE WHEN payment_status = 'Failed' AND retry_attempts = 0 THEN plan_price ELSE 0 END)
                                                               AS recoverable_revenue,
    ROUND(
        SUM(CASE WHEN payment_status = 'Failed' AND retry_attempts = 0 THEN plan_price ELSE 0 END)
        * 0.40, 2
    )                                                          AS estimated_recovery_40pct,
    ROUND(
        SUM(CASE WHEN payment_status = 'Failed' AND retry_attempts = 0 THEN plan_price ELSE 0 END)
        * 0.60, 2
    )                                                          AS estimated_recovery_60pct
FROM payments
GROUP BY payment_method
ORDER BY recoverable_revenue DESC;


-- 7.2 Top 20 High-Value Users at Risk (Prioritise for Outreach)
SELECT
    u.user_id,
    u.name,
    u.country,
    u.subscription_type,
    p.plan_price,
    p.payment_status,
    p.auto_renewal,
    p.retry_attempts,
    CURRENT_DATE - u.last_login                                AS days_since_login,
    u.watch_time_hours,
    ROUND(p.plan_price * 12, 2)                                AS annual_revenue_at_risk
FROM users u
JOIN payments p ON u.user_id = p.user_id
WHERE p.payment_status = 'Failed'
  AND p.auto_renewal = 'No'
ORDER BY p.plan_price DESC, u.watch_time_hours DESC
LIMIT 20;


-- =============================================================================
-- SECTION 8: EXECUTIVE DASHBOARD VIEW
-- =============================================================================

CREATE OR REPLACE VIEW vw_executive_kpi_summary AS
SELECT
    'Total Users'                                              AS kpi,
    CAST(COUNT(DISTINCT u.user_id) AS VARCHAR)                 AS value
FROM users u

UNION ALL

SELECT 'Total Possible Revenue (INR)',
       CAST(ROUND(SUM(p.plan_price), 0) AS VARCHAR)
FROM payments p

UNION ALL

SELECT 'Revenue Earned (INR)',
       CAST(ROUND(SUM(CASE WHEN p.payment_status='Success' THEN p.plan_price ELSE 0 END), 0) AS VARCHAR)
FROM payments p

UNION ALL

SELECT 'Revenue At Risk (INR)',
       CAST(ROUND(SUM(CASE WHEN p.payment_status='Failed' THEN p.plan_price ELSE 0 END), 0) AS VARCHAR)
FROM payments p

UNION ALL

SELECT 'Leakage Rate (%)',
       CAST(ROUND(
           SUM(CASE WHEN p.payment_status='Failed' THEN p.plan_price ELSE 0 END)
           / NULLIF(SUM(p.plan_price), 0) * 100, 2
       ) AS VARCHAR)
FROM payments p

UNION ALL

SELECT 'Payment Failure Rate (%)',
       CAST(ROUND(
           SUM(CASE WHEN p.payment_status='Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
       ) AS VARCHAR)
FROM payments p;

-- Run the executive view
SELECT * FROM vw_executive_kpi_summary;
