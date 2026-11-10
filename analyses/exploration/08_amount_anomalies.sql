-- Check the distribution of amounts by currency and identify anomalies

WITH amounts AS (
    SELECT
        currency,
        amount AS amount_raw,
        SAFE_CAST(amount AS NUMERIC) AS amount
    FROM
        {{ source('globepay', 'acceptance_report') }}
),

stats AS (
    SELECT
        currency,
        AVG(amount) AS avg_amount,
        STDDEV(amount) AS stddev_amount
    FROM
        amounts
    GROUP BY
        ALL
)

SELECT
    a.currency,
    COUNT(*) AS n_rows,
    COUNTIF(a.amount IS NULL AND a.amount_raw IS NOT NULL) AS n_unparseable,
    COUNTIF(a.amount < 0) AS n_negative,
    COUNTIF(a.amount = 0) AS n_zero,
    MIN(a.amount) AS min_amount,
    APPROX_QUANTILES(a.amount, 100)[OFFSET(1)] AS p01_amount,
    APPROX_QUANTILES(a.amount, 100)[OFFSET(50)] AS median_amount,
    APPROX_QUANTILES(a.amount, 100)[OFFSET(99)] AS p99_amount,
    MAX(a.amount) AS max_amount,
    ROUND(ANY_VALUE(s.avg_amount), 2) AS avg_amount,
    COUNTIF(ABS(a.amount - s.avg_amount) > 3 * s.stddev_amount)
        AS n_outliers_3sd
FROM
    amounts AS a 
        INNER JOIN stats AS s ON a.currency = s.currency
GROUP BY
    ALL
ORDER BY
    1
