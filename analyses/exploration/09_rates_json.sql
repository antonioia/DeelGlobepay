-- Check the distribution of rates by currency and identify anomalies

WITH parsed AS (
    SELECT
        currency
        , rates
        , SAFE.PARSE_JSON(rates, wide_number_mode => 'round') AS rates_json
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

, extracted AS (
    SELECT
        *
        , LAX_FLOAT64(rates_json.USD) AS rate_usd
        , LAX_FLOAT64(rates_json[currency]) AS rate_currency
    FROM
        parsed
)

SELECT
    COUNT(*) AS n_rows
    , COUNTIF(rates_json IS NULL) AS n_invalid_json
    , COUNTIF(rate_usd IS NULL) AS n_missing_usd_rate
    , COUNTIF(rate_usd != 1) AS n_usd_rate_not_1
    , COUNTIF(rate_currency IS NULL) AS n_missing_rate_for_currency
    , COUNTIF(rate_currency <= 0) AS n_non_positive_rate
    , COUNT(DISTINCT rates) AS n_distinct_rate_sets
FROM
    extracted
