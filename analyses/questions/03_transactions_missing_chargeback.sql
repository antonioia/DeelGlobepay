-- Q3. Which transactions are missing chargeback data?
-- A transaction is missing chargeback data when it has no row in the chargeback report
-- (`has_chargeback_data = FALSE`; `is_chargeback` is then NULL, i.e. unknown).

SELECT
    transaction_id
    , transaction_at
    , country_code
    , transaction_state
    , amount_local
    , currency_code
    , amount_usd
FROM
    {{ ref('fct_globepay_transactions') }}
WHERE
    NOT has_chargeback_data
ORDER BY
    2
