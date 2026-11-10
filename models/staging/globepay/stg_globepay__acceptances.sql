-- One row per Globepay payment attempt (acceptance report).
-- Renames, casts and USD conversion only: no joins, no business filters.

WITH raw_acceptances AS (
    SELECT
        *
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

, renamed AS (
    SELECT
        -- ids
        external_ref AS transaction_id
        , ref AS event_id
        -- timestamps
        , CAST(date_time AS TIMESTAMP) AS transaction_at
        -- attributes
        , source AS source_system
        , CAST(status AS BOOL) AS is_status_valid
        , state AS transaction_state
        , state = 'ACCEPTED' AS is_accepted
        , CAST(cvv_provided AS BOOL) AS is_cvv_provided
        , country AS country_code
        , currency AS currency_code
        -- amounts
        , CAST(amount AS NUMERIC) AS amount_local
        -- fx: `rates` = units of each currency per 1 USD (USD = 1).
        -- wide_number_mode => 'round' because some rates exceed FLOAT64 precision.
        , PARSE_JSON(rates, wide_number_mode => 'round') AS fx_rates
    FROM
        raw_acceptances
)

, with_fx_rate AS (
    SELECT
        *
        , LAX_FLOAT64(fx_rates[currency_code]) AS fx_rate_to_usd
    FROM
        renamed
)

, converted AS (
    SELECT
        *
        , CAST(amount_local / fx_rate_to_usd AS NUMERIC) AS amount_usd
    FROM
        with_fx_rate
)

SELECT
    *
FROM
    converted
