-- Check the distribution of rates by currency and identify anomalies

WITH rates AS (
    SELECT
        DATE(SAFE_CAST(date_time AS TIMESTAMP)) AS transaction_date
        , currency
        , LAX_FLOAT64(SAFE.PARSE_JSON(rates, wide_number_mode => 'round')[currency]) AS rate
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

, rates_with_daily_count AS (
    SELECT
        *
        -- does the rate stay constant within a day?
        , COUNT(DISTINCT rate) OVER (PARTITION BY currency, transaction_date) AS n_rates_in_day
    FROM
        rates
)

SELECT
    currency
    , COUNT(DISTINCT rate) AS n_distinct_rates
    , COUNT(DISTINCT transaction_date) AS n_days
    , MIN(rate) AS min_rate
    , ROUND(AVG(rate), 4) AS avg_rate
    , MAX(rate) AS max_rate
    , MAX(n_rates_in_day) AS max_distinct_rates_in_one_day
FROM
    rates_with_daily_count
GROUP BY
    ALL
ORDER BY
    1
