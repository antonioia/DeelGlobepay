-- Check the number of transactions and acceptance rate by month

SELECT
    DATE_TRUNC(DATE(SAFE_CAST(date_time AS TIMESTAMP)), MONTH) AS transaction_month
    , COUNT(*) AS n_transactions
    , COUNTIF(state = 'ACCEPTED') AS n_accepted
    , ROUND(COUNTIF(state = 'ACCEPTED') / COUNT(*), 4) AS acceptance_rate
FROM
    {{ source('globepay', 'acceptance_report') }}
GROUP BY
    ALL
ORDER BY
    1
