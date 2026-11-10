-- Q1 by country. Acceptance rate over time, broken down by card country.
-- Acceptance rate = accepted payment attempts / all payment attempts, per country and period.
-- Monthly grain by default: about 150 attempts per country and month (weekly would be about 35, too noisy).

{% set grain = 'MONTH' %}

WITH transactions AS (
    SELECT
        country_code
        , transaction_date
        , is_accepted
    FROM
        {{ ref('fct_globepay_transactions') }}
)

SELECT
    country_code
    , DATE_TRUNC(transaction_date, {{ grain }}) AS period_start
    , COUNT(*) AS n_transactions
    , COUNTIF(is_accepted) AS n_accepted
    , ROUND((COUNTIF(is_accepted) / COUNT(*)) * 100, 2) AS acceptance_rate
FROM
    transactions
GROUP BY
    ALL
ORDER BY
    1
    , 2
