# BANKLEDGER
## Database Design and Normalization Report

**Project:** Banking Transactions and Suspicious Activity Detection  
**Database:** MySQL - BankLedger  
**Storage Engine:** InnoDB  
**Character Set:** utf8mb4

---

## 1. Database Overview

BankLedger is a relational banking database designed to manage customers,
branches, account types, accounts, transactions, loans, suspicious
transaction flags and account balance audit records.

The database contains eight relational tables.

| Table | Purpose |
|---|---|
| customers | Stores customer information |
| branches | Stores bank branch details |
| account_types | Stores available account categories |
| accounts | Stores customer bank accounts and balances |
| transactions | Stores deposits, withdrawals and transfers |
| loans | Stores customer loan information |
| transaction_flags | Stores suspicious transaction alerts |
| balance_audit | Records account balance changes |

## 2. Functional Dependencies

A functional dependency describes how one attribute or a group of
attributes uniquely determines another attribute or group of attributes.

### 2.1 Customers

Primary key: customer_id  
Additional unique key: email (nullable)

Functional dependencies:

- customer_id -> first_name, last_name, email, phone,
  date_of_birth, address, created_at
- email -> customer_id, first_name, last_name, phone,
  date_of_birth, address, created_at (when email is non-NULL)

### 2.2 Branches

Primary key: branch_id

Functional dependency:

- branch_id -> branch_name, city, state

### 2.3 Account Types

Primary key: account_type_id  
Additional unique key: type_name

Functional dependencies:

- account_type_id -> type_name, description
- type_name -> account_type_id, description

### 2.4 Accounts

Primary key: account_id  
Additional unique key: account_number

Functional dependencies:

- account_id -> customer_id, branch_id, account_type_id,
  account_number, opening_date, balance, status
- account_number -> account_id, customer_id, branch_id,
  account_type_id, opening_date, balance, status

### 2.5 Transactions

Primary key: transaction_id

Functional dependency:

- transaction_id -> account_id, transaction_type, amount,
  transaction_date, description, reference_no, transfer_group_id

### 2.6 Loans

Primary key: loan_id

Functional dependency:

- loan_id -> customer_id, branch_id, loan_type,
  principal_amount, interest_rate, start_date, end_date, loan_status

### 2.7 Transaction Flags

Primary key: flag_id

Functional dependency:

- flag_id -> transaction_id, flag_type, severity,
  flag_reason, flagged_at, status

A transaction can have multiple associated flags because transaction_id
is not declared UNIQUE in this table.

### 2.8 Balance Audit

Primary key: audit_id

Functional dependency:

- audit_id -> account_id, old_balance, new_balance,
  changed_at, change_reason

An account can have multiple audit records.

---

## 3. Normalization

Normalization is the process of organizing relational database tables
to reduce unnecessary duplication and prevent insertion, update and
deletion anomalies.

### 3.1 First Normal Form (1NF)

A table satisfies 1NF when:

- Each column contains individual, atomic values.
- Each row can be uniquely identified.
- There are no repeating groups or multi-valued columns.

Assessment:

The eight BankLedger tables use individual columns for customer details,
account information, transaction values, loan information, flags and
audit records.

The tables use primary keys to identify individual records.

Therefore, the inspected schema is consistent with 1NF, assuming
individual values are stored in each field.

### 3.2 Second Normal Form (2NF)

A table satisfies 2NF when:

- It already satisfies 1NF.
- Every non-key attribute depends on the whole candidate key.
- No partial dependency exists on part of a composite candidate key.

Assessment:

All eight tables have single-column primary keys. Their declared
additional unique candidate keys are also single-column.

Therefore, there can be no partial dependency on a subset of a
composite primary key in these tables.

The inspected schema is consistent with 2NF.

### 3.3 Third Normal Form (3NF)

A table satisfies 3NF when:

- It already satisfies 2NF.
- Non-key attributes do not depend transitively on candidate keys
  through other non-key attributes.

Assessment:

BankLedger separates customers, branches, account types and accounts
into different tables.

For example:

- Customer details are stored in customers.
- Branch details are stored in branches.
- Account category details are stored in account_types.
- Accounts reference these entities using foreign keys.

This avoids repeatedly storing customer, branch and account-type
descriptions in every related account or transaction record.

Based on the declared keys and intended business meanings, the
inspected schema is consistent with 3NF.

Note: This is a schema-level assessment. Full proof of 3NF also depends
on all business-rule functional dependencies, not only declared keys.

---

## 4. Primary Keys and Unique Constraints

| Table | Primary Key | Additional Unique Key |
|---|---|---|
| customers | customer_id | email |
| branches | branch_id | None |
| account_types | account_type_id | type_name |
| accounts | account_id | account_number |
| transactions | transaction_id | None |
| loans | loan_id | None |
| transaction_flags | flag_id | None |
| balance_audit | audit_id | None |

Note: The customers.email column is nullable. MySQL permits multiple
NULL values in a UNIQUE column.

## 5. Foreign Key Relationships

| Child Table | Foreign Key | Parent Table |
|---|---|---|
| accounts | customer_id | customers |
| accounts | branch_id | branches |
| accounts | account_type_id | account_types |
| transactions | account_id | accounts |
| loans | customer_id | customers |
| loans | branch_id | branches |
| transaction_flags | transaction_id | transactions |
| balance_audit | account_id | accounts |

These relationships maintain referential integrity between related
banking records.

## 6. Check Constraints

| Table | Constraint | Rule |
|---|---|---|
| accounts | accounts_chk_1 | balance >= 0 |
| transactions | transactions_chk_1 | amount > 0 |
| loans | loans_chk_1 | principal_amount > 0 |
| loans | loans_chk_2 | interest_rate >= 0 |

These constraints prevent invalid balance, transaction and loan values.

## 7. Transaction Types

The transactions table supports four transaction types:

- DEPOSIT
- WITHDRAWAL
- TRANSFER_IN
- TRANSFER_OUT

The transfer_group_id column is available to associate related
transfer records.

## 8. Database Integrity

The database uses:

- Primary keys for unique record identification.
- Unique constraints to prevent duplicate candidate-key values.
- Foreign keys to maintain relationships.
- Check constraints to restrict invalid numeric values.
- Database triggers for transaction balance updates and audit logging.

## 9. Conclusion

The BankLedger database separates major banking entities into eight
related tables. Its primary keys, unique constraints, foreign keys
and check constraints support data integrity.

The schema-level assessment indicates consistency with 1NF, 2NF
and 3NF under the stated business assumptions.

This database design provides a structured foundation for banking
transaction analysis, suspicious activity monitoring and reporting.