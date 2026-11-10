-- Check that all transactions in the acceptance report are also present in the chargeback report and vice versa 
-- and that the state and chargeback columns are consistent across the two tables

WITH acceptance AS (
    SELECT
        external_ref
        , state
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

, chargeback AS (
    SELECT
        external_ref
        , chargeback
    FROM
        {{ source('globepay', 'chargeback_report') }}
)

, joined AS (
    SELECT
        a.external_ref IS NOT NULL AS in_acceptance
        , c.external_ref IS NOT NULL AS in_chargeback
        , a.state
        , c.chargeback
    FROM
        acceptance AS a
    FULL OUTER JOIN
        chargeback AS c
        ON a.external_ref = c.external_ref
)

SELECT
    CASE
        WHEN in_acceptance AND in_chargeback THEN 'in both'
        WHEN in_acceptance THEN 'acceptance only (missing chargeback data)'
        ELSE 'chargeback only (orphan)'
    END AS coverage
    , state
    , chargeback
    , COUNT(*) AS n_transactions
    , ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM
    joined
GROUP BY
    ALL
ORDER BY
    1,2,3

