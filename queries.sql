
-- =====================================================
-- BANKLEDGER PROJECT
-- SQL ANALYSIS AND REPORTING QUERIES
-- =====================================================

USE BankLedger;


-- =====================================================
-- 1. DISPLAY ALL DATABASE TABLES
-- =====================================================

SHOW TABLES;


-- =====================================================
-- 2. CUSTOMER ACCOUNT SUMMARY
-- =====================================================

SELECT *
FROM customer_account_summary
LIMIT 10;


-- =====================================================
-- 3. BRANCH-WISE DEPOSIT ANALYSIS
-- =====================================================

SELECT
    b.branch_name,
    b.city,
    COUNT(t.transaction_id) AS total_deposits,
    SUM(t.amount) AS total_deposit_amount,
    ROUND(AVG(t.amount), 2) AS average_deposit
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.transaction_type = 'DEPOSIT'
GROUP BY
    b.branch_id,
    b.branch_name,
    b.city
ORDER BY total_deposit_amount DESC;


-- =====================================================
-- 4. DORMANT ACCOUNT ANALYSIS
-- =====================================================

SELECT
    customer_id,
    customer_name,
    account_id,
    account_number,
    branch_name,
    balance,
    account_status
FROM customer_account_summary
WHERE account_status = 'DORMANT'
ORDER BY balance DESC;


-- =====================================================
-- 5. HIGH-VALUE CUSTOMER ANALYSIS
-- Minimum total balance: 300000
-- =====================================================

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(a.account_id) AS total_accounts,
    SUM(a.balance) AS total_balance
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING SUM(a.balance) >= 300000
ORDER BY total_balance DESC;


-- =====================================================
-- 6. SUSPICIOUS TRANSACTION FLAG ANALYSIS
-- =====================================================

SELECT
    t.transaction_id,
    t.account_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    t.transaction_type,
    t.amount,
    t.transaction_date,
    tf.flag_type,
    tf.severity,
    tf.flag_reason,
    tf.status
FROM transactions t
JOIN accounts a
    ON t.account_id = a.account_id
JOIN customers c
    ON a.customer_id = c.customer_id
JOIN transaction_flags tf
    ON t.transaction_id = tf.transaction_id
ORDER BY t.amount DESC;


-- =====================================================
-- 7. REPEATED HIGH-VALUE DEPOSIT ANALYSIS
-- Minimum deposit: 80000
-- Minimum occurrences: 2
-- =====================================================

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(t.transaction_id) AS high_value_deposits,
    SUM(t.amount) AS total_deposit_amount,
    MAX(t.amount) AS highest_deposit
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.transaction_type = 'DEPOSIT'
AND t.amount >= 80000
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(t.transaction_id) >= 2
ORDER BY
    high_value_deposits DESC,
    total_deposit_amount DESC;


-- =====================================================
-- 8. TRANSACTION TYPE SUMMARY
-- =====================================================

SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM transactions
GROUP BY transaction_type
ORDER BY total_amount DESC;


-- =====================================================
-- 9. TRANSACTION FLAG SUMMARY
-- =====================================================

SELECT
    flag_type,
    severity,
    status,
    COUNT(*) AS total_flags
FROM transaction_flags
GROUP BY
    flag_type,
    severity,
    status
ORDER BY total_flags DESC;


-- =====================================================
-- 10. ACCOUNT BALANCE AUDIT HISTORY
-- =====================================================

SELECT
    audit_id,
    account_id,
    old_balance,
    new_balance,
    changed_at,
    change_reason
FROM balance_audit
ORDER BY changed_at DESC
LIMIT 20;


-- =====================================================
-- 11. TEST TRANSACTION TRANSFER
-- Demonstration only: transaction is rolled back.
-- =====================================================

SELECT account_id, balance
FROM accounts
WHERE account_id IN (1, 2);

START TRANSACTION;

-- Transfer OUT from Account 1

INSERT INTO transactions
(
    account_id,
    transaction_type,
    amount,
    transaction_date,
    description,
    reference_no,
    transfer_group_id
)
VALUES
(
    1,
    'TRANSFER_OUT',
    1000.00,
    NOW(),
    'Test transfer to Account 2',
    'TEST-REF-001',
    'TEST-TRANSFER-001'
);

-- Transfer IN to Account 2

INSERT INTO transactions
(
    account_id,
    transaction_type,
    amount,
    transaction_date,
    description,
    reference_no,
    transfer_group_id
)
VALUES
(
    2,
    'TRANSFER_IN',
    1000.00,
    NOW(),
    'Test transfer from Account 1',
    'TEST-REF-001',
    'TEST-TRANSFER-001'
);

-- Verify temporary balances

SELECT account_id, balance
FROM accounts
WHERE account_id IN (1, 2);

-- Verify temporary transfer records

SELECT
    transaction_id,
    account_id,
    transaction_type,
    amount,
    transfer_group_id
FROM transactions
WHERE transfer_group_id = 'TEST-TRANSFER-001';

-- Undo test transaction

ROLLBACK;

-- Verify original balances

SELECT account_id, balance
FROM accounts
WHERE account_id IN (1, 2);


-- =====================================================
-- END OF BANKLEDGER SQL ANALYSIS
-- =====================================================
