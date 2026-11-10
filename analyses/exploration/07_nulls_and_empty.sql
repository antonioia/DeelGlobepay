-- Check for nulls and empty strings in all columns of the acceptance_report and chargeback_report tables, using UNPIVOT to transform the data into a long format for easier aggregation.

WITH unpivoted AS (
    SELECT
        'acceptance_report' AS table_name
        , column_name
        , value
    FROM
        {{ source('globepay', 'acceptance_report') }}
            UNPIVOT INCLUDE NULLS (value FOR column_name IN (
                external_ref, status, source, ref, date_time, state, cvv_provided, amount, country, currency, rates
        ))
    UNION ALL
    SELECT
        'chargeback_report' AS table_name
        , column_name
        , value
    FROM
        {{ source('globepay', 'chargeback_report') }}
            UNPIVOT INCLUDE NULLS (value FOR column_name IN (external_ref, status, source, chargeback))
)

SELECT
    table_name
    , column_name
    , COUNTIF(NULLIF(TRIM(value), '') IS NULL) AS n_null_or_empty
    , COUNT(*) AS n_rows
FROM
    unpivoted
GROUP BY
    ALL
ORDER BY
    1,2

