-- Check how many currencies are associated with each country in the acceptance report. This is to ensure that we have a 1:1 mapping between country and currency.

SELECT
    country
    , currency
    , COUNT(*) AS n_rows
    , COUNT(*) OVER (PARTITION BY country) AS n_currencies_for_country
FROM
    {{ source('globepay', 'acceptance_report') }}
GROUP BY
    ALL
ORDER BY
    1,2

