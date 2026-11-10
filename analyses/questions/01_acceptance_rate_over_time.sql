-- Q1. What is the acceptance rate over time?
-- Acceptance rate = accepted payment attempts / all payment attempts in the period.
-- Change `grain` to 'DAY', 'ISOWEEK' or 'MONTH' to get a different time granularity.

{% set grain = 'ISOWEEK' %}

WITH transactions AS (
    SELECT
        transaction_date
        , is_accepted
    FROM
        {{ ref('fct_globepay_transactions') }}
)

SELECT
    DATE_TRUNC(transaction_date, {{ grain }}) AS period_start
    , COUNT(*) AS n_transactions
    , COUNTIF(is_accepted) AS n_accepted
    , ROUND((COUNTIF(is_accepted) / COUNT(*)) * 100, 2) AS acceptance_rate
FROM
    transactions
GROUP BY
    ALL
ORDER BY
    1
