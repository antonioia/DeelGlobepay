-- Q2 over time. On which day did each country's declined amount go over $25M?
-- Running total of declined `amount_usd` per country, in time order; the crossing day is the first day it is above the threshold.
-- Countries that never cross have `crossed_on` = NULL.

{% set threshold_usd = 25000000 %}

WITH declined AS (
    SELECT
        country_code
        , transaction_id
        , transaction_at
        , amount_usd
    FROM
        {{ ref('fct_globepay_transactions') }}
    WHERE
        NOT is_accepted
)

, running_total AS (
    SELECT
        *
        , SUM(amount_usd) OVER (
            PARTITION BY country_code
            ORDER BY transaction_at, transaction_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_declined_usd
    FROM
        declined
)

, first_crossing AS (
    SELECT
        country_code
        , MIN(transaction_at) AS crossed_at
    FROM
        running_total
    WHERE
        cumulative_declined_usd > {{ threshold_usd }}
    GROUP BY
        ALL
)

, totals AS (
    SELECT
        country_code
        , COUNT(*) AS n_declined_transactions
        , SUM(amount_usd) AS declined_amount_usd
    FROM
        declined
    GROUP BY
        ALL
)

, period_end AS (
    SELECT
        MAX(transaction_date) AS last_date
    FROM
        {{ ref('fct_globepay_transactions') }}
)

SELECT
    t.country_code
    , t.n_declined_transactions
    , ROUND(t.declined_amount_usd, 2) AS declined_amount_usd
    , DATE(f.crossed_at) AS crossed_on
    , DATE_DIFF(p.last_date, DATE(f.crossed_at), DAY) AS days_before_period_end
FROM
    totals AS t
LEFT JOIN
    first_crossing AS f
    ON t.country_code = f.country_code
CROSS JOIN
    period_end AS p
ORDER BY
    f.crossed_at NULLS LAST
    , t.declined_amount_usd DESC
