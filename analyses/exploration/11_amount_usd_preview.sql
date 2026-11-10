-- Check the distribution of amounts by currency and identify anomalies

WITH converted AS (
    SELECT
        country
        , currency
        , state
        , SAFE_CAST(amount AS NUMERIC) AS amount_local
        , LAX_FLOAT64(SAFE.PARSE_JSON(rates, wide_number_mode => 'round')[currency]) AS rate
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

SELECT
    country
    , currency
    , state
    , COUNT(*) AS n_transactions
    , ROUND(SUM(amount_local), 2) AS total_amount_local
    , ROUND(CAST(SUM(amount_local / rate) AS NUMERIC), 2) AS total_amount_usd
    , ROUND(CAST(AVG(amount_local / rate) AS NUMERIC), 2) AS avg_amount_usd
FROM
    converted
GROUP BY
    ALL
ORDER BY
    1,3

