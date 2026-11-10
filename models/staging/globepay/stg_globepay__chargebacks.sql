-- One row per Globepay transaction with its chargeback flag (chargeback report).

WITH raw_chargebacks AS (
    SELECT
        *
    FROM
        {{ source('globepay', 'chargeback_report') }}
)

, renamed AS (
    SELECT
        -- ids
        external_ref AS transaction_id
        -- attributes
        , source AS source_system
        , CAST(status AS BOOL) AS is_status_valid
        , CAST(chargeback AS BOOL) AS is_chargeback
    FROM
        raw_chargebacks
)

SELECT
    *
FROM
    renamed
