-- One row per Globepay payment attempt, enriched with its chargeback status.
-- Production model for the Data Analyst: acceptance rate, declined amounts in USD,
-- transactions missing chargeback data.
-- LEFT JOIN from acceptances so that no payment attempt is lost when the chargeback report has no row for it.

WITH acceptances AS (
    SELECT
        *
    FROM
        {{ ref('stg_globepay__acceptances') }}
)

, chargebacks AS (
    SELECT
        *
    FROM
        {{ ref('stg_globepay__chargebacks') }}
)

, joined AS (
    SELECT
        -- ids
        a.transaction_id
        , a.event_id
        -- timestamps
        , a.transaction_at
        , DATE(a.transaction_at) AS transaction_date
        -- attributes
        , a.country_code
        , a.currency_code
        , a.transaction_state
        , a.is_accepted
        , a.is_cvv_provided
        -- amounts
        , a.amount_local
        , a.fx_rate_to_usd
        , a.amount_usd
        -- chargeback
        , c.transaction_id IS NOT NULL AS has_chargeback_data
        , c.is_chargeback
    FROM
        acceptances AS a
    LEFT JOIN
        chargebacks AS c
        ON a.transaction_id = c.transaction_id
)

SELECT
    *
FROM
    joined
