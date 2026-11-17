
-- =====================================================
-- BANKLEDGER PROJECT
-- DATA IMPORT AND VALIDATION
-- =====================================================

USE BankLedger;

-- DATA SOURCE
-- The project datasets were generated using Python
-- and stored as CSV files in the datasets folder.
--
-- CSV files:
-- 1. customers.csv
-- 2. branches.csv
-- 3. account_types.csv
-- 4. accounts.csv
-- 5. transactions.csv
-- 6. loans.csv
-- 7. transaction_flags.csv
--
-- DATA IMPORT METHOD
-- Data was imported into MySQL using Python,
-- Pandas and mysql-connector-python in Jupyter Notebook.
--
-- Import order followed foreign key dependencies:
-- 1. customers
-- 2. branches
-- 3. account_types
-- 4. accounts
-- 5. transactions
-- 6. loans
-- 7. transaction_flags
--
-- The balance_audit table was populated automatically
-- by the account balance update trigger.

-- =====================================================
-- RECORD COUNT VALIDATION
-- =====================================================

SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM customers

UNION ALL

SELECT 'branches', COUNT(*)
FROM branches

UNION ALL

SELECT 'account_types', COUNT(*)
FROM account_types

UNION ALL

SELECT 'accounts', COUNT(*)
FROM accounts

UNION ALL

SELECT 'transactions', COUNT(*)
FROM transactions

UNION ALL

SELECT 'loans', COUNT(*)
FROM loans

UNION ALL

SELECT 'transaction_flags', COUNT(*)
FROM transaction_flags

UNION ALL

SELECT 'balance_audit', COUNT(*)
FROM balance_audit;

-- =====================================================
-- END OF DATA IMPORT DOCUMENTATION
-- =====================================================
