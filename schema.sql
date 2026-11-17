
USE BankLedger;

-- =========================================
-- 1. BALANCE AUDIT TABLE
-- =========================================

CREATE TABLE balance_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    old_balance DECIMAL(15,2),
    new_balance DECIMAL(15,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_reason VARCHAR(100),
    FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);

-- =========================================
-- 2. TRIGGERS
-- =========================================

DELIMITER $$

-- Trigger 1: Check balance before withdrawal

CREATE TRIGGER before_transaction_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);

    SELECT balance INTO current_balance
    FROM accounts
    WHERE account_id = NEW.account_id
    FOR UPDATE;

    IF NEW.transaction_type IN ('WITHDRAWAL', 'TRANSFER_OUT') THEN
        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient account balance';
        END IF;
    END IF;
END$$

-- Trigger 2: Automatically update account balance

CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type IN ('DEPOSIT', 'TRANSFER_IN') THEN
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;

    ELSEIF NEW.transaction_type IN ('WITHDRAWAL', 'TRANSFER_OUT') THEN
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;
END$$

-- Trigger 3: Maintain balance audit history

CREATE TRIGGER after_account_balance_update
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF OLD.balance <> NEW.balance THEN
        INSERT INTO balance_audit (
            account_id,
            old_balance,
            new_balance,
            change_reason
        )
        VALUES (
            NEW.account_id,
            OLD.balance,
            NEW.balance,
            'Transaction-driven balance update'
        );
    END IF;
END$$

DELIMITER ;

-- =========================================
-- 3. CUSTOMER ACCOUNT SUMMARY VIEW
-- =========================================

CREATE OR REPLACE VIEW customer_account_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_id,
    a.account_number,
    at.type_name AS account_type,
    b.branch_name,
    b.city,
    a.balance,
    a.status AS account_status
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN account_types at
    ON a.account_type_id = at.account_type_id
JOIN branches b
    ON a.branch_id = b.branch_id;
SHOW CREATE TABLE customers;
SHOW CREATE TABLE branches;
SHOW CREATE TABLE account_types;
SHOW CREATE TABLE accounts;
SHOW CREATE TABLE transactions;
SHOW CREATE TABLE loans;
SHOW CREATE TABLE transaction_flags;


-- =====================================================
-- BANKLEDGER PROJECT
-- DATABASE SCHEMA
-- =====================================================

CREATE DATABASE IF NOT EXISTS BankLedger;
USE BankLedger;

-- =====================================================
-- 1. CUSTOMERS TABLE
-- =====================================================

CREATE TABLE customers (
    customer_id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) DEFAULT NULL,
    phone VARCHAR(15) DEFAULT NULL,
    date_of_birth DATE DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    UNIQUE KEY email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 2. BRANCHES TABLE
-- =====================================================

CREATE TABLE branches (
    branch_id INT NOT NULL AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    PRIMARY KEY (branch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 3. ACCOUNT TYPES TABLE
-- =====================================================

CREATE TABLE account_types (
    account_type_id INT NOT NULL AUTO_INCREMENT,
    type_name VARCHAR(30) NOT NULL,
    description VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (account_type_id),
    UNIQUE KEY type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 4. ACCOUNTS TABLE
-- =====================================================

CREATE TABLE accounts (
    account_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_type_id INT NOT NULL,
    account_number VARCHAR(20) NOT NULL,
    opening_date DATE NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT '0.00',
    status VARCHAR(20) DEFAULT 'ACTIVE',

    PRIMARY KEY (account_id),
    UNIQUE KEY account_number (account_number),
    KEY customer_id (customer_id),
    KEY branch_id (branch_id),
    KEY account_type_id (account_type_id),

    CONSTRAINT accounts_ibfk_1
        FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id),

    CONSTRAINT accounts_ibfk_2
        FOREIGN KEY (branch_id)
        REFERENCES branches (branch_id),

    CONSTRAINT accounts_ibfk_3
        FOREIGN KEY (account_type_id)
        REFERENCES account_types (account_type_id),

    CONSTRAINT accounts_chk_1
        CHECK (balance >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 5. TRANSACTIONS TABLE
-- =====================================================

CREATE TABLE transactions (
    transaction_id INT NOT NULL AUTO_INCREMENT,
    account_id INT NOT NULL,

    transaction_type ENUM(
        'DEPOSIT',
        'WITHDRAWAL',
        'TRANSFER_IN',
        'TRANSFER_OUT'
    ) NOT NULL,

    amount DECIMAL(15,2) NOT NULL,
    transaction_date DATETIME NOT NULL,
    description VARCHAR(255) DEFAULT NULL,
    reference_no VARCHAR(50) DEFAULT NULL,
    transfer_group_id VARCHAR(50) DEFAULT NULL,

    PRIMARY KEY (transaction_id),
    KEY account_id (account_id),

    CONSTRAINT transactions_ibfk_1
        FOREIGN KEY (account_id)
        REFERENCES accounts (account_id),

    CONSTRAINT transactions_chk_1
        CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 6. LOANS TABLE
-- =====================================================

CREATE TABLE loans (
    loan_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    loan_type VARCHAR(50) NOT NULL,
    principal_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT NULL,
    loan_status VARCHAR(20) DEFAULT 'ACTIVE',

    PRIMARY KEY (loan_id),
    KEY customer_id (customer_id),
    KEY branch_id (branch_id),

    CONSTRAINT loans_ibfk_1
        FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id),

    CONSTRAINT loans_ibfk_2
        FOREIGN KEY (branch_id)
        REFERENCES branches (branch_id),

    CONSTRAINT loans_chk_1
        CHECK (principal_amount > 0),

    CONSTRAINT loans_chk_2
        CHECK (interest_rate >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 7. TRANSACTION FLAGS TABLE
-- =====================================================

CREATE TABLE transaction_flags (
    flag_id INT NOT NULL AUTO_INCREMENT,
    transaction_id INT NOT NULL,
    flag_type VARCHAR(50) NOT NULL,
    severity ENUM('LOW','MEDIUM','HIGH') NOT NULL,
    flag_reason VARCHAR(255) DEFAULT NULL,
    flagged_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'OPEN',

    PRIMARY KEY (flag_id),
    KEY transaction_id (transaction_id),

    CONSTRAINT transaction_flags_ibfk_1
        FOREIGN KEY (transaction_id)
        REFERENCES transactions (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 8. BALANCE AUDIT TABLE
-- =====================================================

CREATE TABLE balance_audit (
    audit_id INT NOT NULL AUTO_INCREMENT,
    account_id INT NOT NULL,
    old_balance DECIMAL(15,2) DEFAULT NULL,
    new_balance DECIMAL(15,2) DEFAULT NULL,
    changed_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    change_reason VARCHAR(100) DEFAULT NULL,

    PRIMARY KEY (audit_id),
    KEY account_id (account_id),

    CONSTRAINT balance_audit_ibfk_1
        FOREIGN KEY (account_id)
        REFERENCES accounts (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =====================================================
-- 9. TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger 1: Check account balance before withdrawal

CREATE TRIGGER before_transaction_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);

    SELECT balance INTO current_balance
    FROM accounts
    WHERE account_id = NEW.account_id
    FOR UPDATE;

    IF NEW.transaction_type IN ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient account balance';
        END IF;

    END IF;
END$$


-- Trigger 2: Automatically update account balance

CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN

    IF NEW.transaction_type IN ('DEPOSIT', 'TRANSFER_IN') THEN

        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;

    ELSEIF NEW.transaction_type IN ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;

    END IF;

END$$


-- Trigger 3: Maintain balance audit history

CREATE TRIGGER after_account_balance_update
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN

    IF OLD.balance <> NEW.balance THEN

        INSERT INTO balance_audit (
            account_id,
            old_balance,
            new_balance,
            change_reason
        )
        VALUES (
            NEW.account_id,
            OLD.balance,
            NEW.balance,
            'Transaction-driven balance update'
        );

    END IF;

END$$

DELIMITER ;


-- =====================================================
-- 10. CUSTOMER ACCOUNT SUMMARY VIEW
-- =====================================================

CREATE OR REPLACE VIEW customer_account_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_id,
    a.account_number,
    at.type_name AS account_type,
    b.branch_name,
    b.city,
    a.balance,
    a.status AS account_status

FROM customers c

JOIN accounts a
    ON c.customer_id = a.customer_id

JOIN account_types at
    ON a.account_type_id = at.account_type_id

JOIN branches b
    ON a.branch_id = b.branch_id;


-- =====================================================
-- END OF BANKLEDGER DATABASE SCHEMA
-- =====================================================
