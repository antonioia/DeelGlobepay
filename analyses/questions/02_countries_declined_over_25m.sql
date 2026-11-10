-- Q2. List the countries where the amount of declined transactions went over $25M.
-- Amounts are compared in USD (`amount_usd`), so that countries with different currencies are comparable.
-- Total over the whole period covered by the data.

WITH declined AS (
    SELECT
        country_code
        , amount_usd
    FROM
        {{ ref('fct_globepay_transactions') }}
    WHERE
        NOT is_accepted
)

SELECT
    country_code
    , COUNT(*) AS n_declined_transactions
    , ROUND(SUM(amount_usd), 2) AS declined_amount_usd
FROM
    declined
GROUP BY
    ALL
HAVING
    SUM(amount_usd) > 25000000
ORDER BY
    3 DESC
