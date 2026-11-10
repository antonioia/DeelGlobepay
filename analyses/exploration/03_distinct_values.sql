-- Check that the values in the categorical columns are consistent across the two tables and count the number of distinct values and their frequency

WITH unpivoted AS (
    SELECT
        'acceptance_report' AS table_name
        , column_name
        , value
    FROM
        {{ source('globepay', 'acceptance_report') }}
        UNPIVOT INCLUDE NULLS (value FOR column_name IN (status, source, state, cvv_provided, currency, country))
    UNION ALL
    SELECT
        'chargeback_report' AS table_name
        , column_name
        , value
    FROM
        {{ source('globepay', 'chargeback_report') }}
        UNPIVOT INCLUDE NULLS (value FOR column_name IN (status, source, chargeback))
)

, value_counts AS (
    SELECT
        table_name
        , column_name
        , value
        , COUNT(*) AS n_rows
    FROM
        unpivoted
    GROUP BY
        ALL
)

SELECT
    table_name
    , column_name
    , COUNT(*) OVER (PARTITION BY table_name, column_name) AS n_distinct_values
    , value
    , n_rows
    , ROUND(100 * n_rows / SUM(n_rows) OVER (PARTITION BY table_name, column_name), 2) AS pct_rows
FROM
    value_counts
ORDER BY
    1,2,5 DESC
