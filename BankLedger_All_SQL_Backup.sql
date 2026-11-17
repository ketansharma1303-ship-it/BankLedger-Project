
USE BankLedger;

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

SHOW TABLES;
DELIMITER $$

-- TRIGGER 1: Check balance before withdrawal

CREATE TRIGGER before_transaction_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);

    SELECT balance INTO current_balance
    FROM accounts
    WHERE account_id = NEW.account_id
    FOR UPDATE;

    IF NEW.transaction_type IN
       ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient account balance';
        END IF;

    END IF;
END$$


-- TRIGGER 2: Automatically update account balance

CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN

    IF NEW.transaction_type IN
       ('DEPOSIT', 'TRANSFER_IN') THEN

        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;

    ELSEIF NEW.transaction_type IN
       ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;

    END IF;

END$$


-- TRIGGER 3: Maintain balance audit history

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


SHOW TRIGGERS FROM BankLedger;
DELIMITER $$

-- TRIGGER 1: Check balance before withdrawal

CREATE TRIGGER before_transaction_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);

    SELECT balance INTO current_balance
    FROM accounts
    WHERE account_id = NEW.account_id
    FOR UPDATE;

    IF NEW.transaction_type IN
       ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient account balance';
        END IF;

    END IF;
END$$


-- TRIGGER 2: Update balance automatically

CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN

    IF NEW.transaction_type IN
       ('DEPOSIT', 'TRANSFER_IN') THEN

        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;

    ELSEIF NEW.transaction_type IN
       ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;

    END IF;

END$$

DELIMITER ;

SHOW TRIGGERS FROM BankLedger;

DELIMITER $$

CREATE TRIGGER before_transaction_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);

    SELECT balance INTO current_balance
    FROM accounts
    WHERE account_id = NEW.account_id
    FOR UPDATE;

    IF NEW.transaction_type IN
       ('WITHDRAWAL', 'TRANSFER_OUT') THEN

        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient account balance';
        END IF;

    END IF;
END$$

DELIMITER ;


SHOW TRIGGERS FROM BankLedger;

DESCRIBE transactions;

DESCRIBE loans;

DESCRIBE transaction_flags;

DESCRIBE transactions;

DESCRIBE loans;
DESCRIBE transactions;

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
    SELECT *
FROM customer_account_summary
LIMIT 10;

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
ORDER BY high_value_deposits DESC,
         total_deposit_amount DESC;
         
         SELECT account_id, balance
FROM accounts
WHERE account_id IN (1, 2);

START TRANSACTION;

-- Step A: Transfer ₹1,000 OUT of Account 1
INSERT INTO transactions
(account_id, transaction_type, amount, transaction_date,
 description, reference_no, transfer_group_id)
VALUES
(1, 'TRANSFER_OUT', 1000.00, NOW(),
 'Test transfer to Account 2', 'TEST-REF-001', 'TEST-TRANSFER-001');

-- Step B: Transfer ₹1,000 INTO Account 2
INSERT INTO transactions
(account_id, transaction_type, amount, transaction_date,
 description, reference_no, transfer_group_id)
VALUES
(2, 'TRANSFER_IN', 1000.00, NOW(),
 'Test transfer from Account 1', 'TEST-REF-001', 'TEST-TRANSFER-001');

-- Step C: Check temporary balances
SELECT account_id, balance
FROM accounts
WHERE account_id IN (1, 2);

-- Step D: Check temporary transfer records
SELECT transaction_id, account_id, transaction_type,
       amount, transfer_group_id
FROM transactions
WHERE transfer_group_id = 'TEST-TRANSFER-001';

-- Step E: Undo the test and restore original data
ROLLBACK;

-- Step F: Verify original balances are restored
SELECT account_id, balance
FROM accounts
WHERE account_id IN (1, 2);