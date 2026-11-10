-- Check that the date_time column can be parsed into a timestamp and that every day between the first and last transaction has data, comparing the daily counts against a calendar built with GENERATE_DATE_ARRAY

WITH parsed AS (
    SELECT
        date_time
        , SAFE_CAST(date_time AS TIMESTAMP) AS transaction_at
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

, daily AS (
    SELECT
        DATE(transaction_at) AS transaction_date
        , COUNT(*) AS n_rows
    FROM
        parsed
    WHERE
        transaction_at IS NOT NULL
    GROUP BY
        ALL
)

, bounds AS (
    SELECT
        MIN(transaction_date) AS min_date
        , MAX(transaction_date) AS max_date
    FROM
        daily
)

, calendar AS (
    SELECT
        calendar_date
    FROM
        bounds
        CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(bounds.min_date, bounds.max_date, INTERVAL 1 DAY)) AS calendar_date
)

, calendar_daily AS (
    SELECT
        c.calendar_date
        , COALESCE(d.n_rows, 0) AS n_rows
    FROM
        calendar AS c
        LEFT JOIN daily AS d
            ON c.calendar_date = d.transaction_date
)

, summary_parsed AS (
    SELECT
        COUNT(*) AS n_rows
        , COUNTIF(transaction_at IS NULL) AS n_unparseable_date_time
        , MIN(transaction_at) AS min_transaction_at
        , MAX(transaction_at) AS max_transaction_at
    FROM
        parsed
)

, summary_daily AS (
    SELECT
        COUNT(*) AS n_calendar_days
        , COUNTIF(n_rows > 0) AS n_days_with_data
        , COUNTIF(n_rows = 0) AS n_missing_days
        , ARRAY_AGG(IF(n_rows = 0, calendar_date, NULL) IGNORE NULLS ORDER BY calendar_date) AS missing_dates
        , MIN(n_rows) AS min_rows_per_day
        , MAX(n_rows) AS max_rows_per_day
        , ROUND(AVG(n_rows), 1) AS avg_rows_per_day
    FROM
        calendar_daily
)

SELECT
    p.*
    , d.*
FROM
    summary_parsed AS p
        CROSS JOIN summary_daily AS d
