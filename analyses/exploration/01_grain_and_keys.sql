-- Check that external_ref is unique and not-null in both the tables and
-- n_rows = n_distinct_external_ref and n_null_external_ref = 0.
-- Also check the ID mapping against the API spec: the spec example shows `evt_...` as `external_ref`,
-- but in the CSV the `evt_...` values are in `ref`. The chargeback report must match one of the two.

WITH acceptance AS (
    SELECT
        'acceptance_report' AS table_name
        , external_ref
        , ref
    FROM
        {{ source('globepay', 'acceptance_report') }}
)

, chargeback AS (
    SELECT
        'chargeback_report' AS table_name
        , external_ref
        , CAST(NULL AS STRING) AS ref
    FROM
        {{ source('globepay', 'chargeback_report') }}
)

, unioned AS (
    SELECT
        *
    FROM
        acceptance
    UNION ALL
    SELECT
        *
    FROM
        chargeback
)

, per_table AS (
    SELECT
        table_name
        , COUNT(*) AS n_rows
        , COUNT(DISTINCT external_ref) AS n_distinct_external_ref
        , COUNTIF(external_ref IS NULL OR external_ref = '') AS n_null_external_ref
        , COUNT(*) - COUNT(DISTINCT external_ref) AS n_duplicate_external_ref
        -- `ref` (event id) only exists in the acceptance report
        , COUNT(DISTINCT ref) AS n_distinct_ref
        , COUNTIF(STARTS_WITH(external_ref, 'evt_')) AS n_external_ref_evt_prefix
        , COUNTIF(STARTS_WITH(ref, 'evt_')) AS n_ref_evt_prefix
    FROM
        unioned
    GROUP BY
        ALL
)

-- Which acceptance column does the chargeback key match?
, chargeback_key_match AS (
    SELECT
        c.table_name
        , COUNT(a_ext.external_ref) AS n_match_acceptance_external_ref
        , COUNT(a_ref.ref) AS n_match_acceptance_ref
    FROM
        chargeback AS c
    LEFT JOIN
        acceptance AS a_ext
        ON c.external_ref = a_ext.external_ref
    LEFT JOIN
        acceptance AS a_ref
        ON c.external_ref = a_ref.ref
    GROUP BY
        ALL
)

SELECT
    p.*
    , k.n_match_acceptance_external_ref
    , k.n_match_acceptance_ref
FROM
    per_table AS p
LEFT JOIN
    chargeback_key_match AS k
    ON p.table_name = k.table_name
ORDER BY
    1
