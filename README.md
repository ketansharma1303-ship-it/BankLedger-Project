# BankLedger – Banking Transactions and Suspicious Activity Detection

A banking database and analytics project built using **MySQL, Python, MongoDB, and Streamlit**.

## Project Overview

BankLedger is an educational banking analytics project designed to manage banking records, analyse transaction activity, monitor high-value transactions, and demonstrate rule-based suspicious activity detection.

## Technologies Used

- **MySQL:** Relational database, constraints, triggers, stored procedures, views, and SQL analytics.
- **Python:** Data processing, database connectivity, transaction analysis, and visualisation.
- **Pandas:** Data cleaning and analysis.
- **Matplotlib:** Daily and hourly transaction charts.
- **MongoDB Atlas:** Transaction document storage, CRUD operations, indexes, and aggregation pipelines.
- **Streamlit:** Interactive banking dashboard.

## Database Structure

The MySQL database contains eight tables:

1. customers
2. branches
3. account_types
4. accounts
5. transactions
6. loans
7. transaction_flags
8. balance_audit

## Project Features

- Banking customer and account management.
- Deposit and withdrawal transaction processing.
- Fund transfers using stored procedures.
- Automatic account balance updates using triggers.
- Balance audit logging.
- Branch-wise deposit analysis.
- Dormant account and high-value customer analysis.
- Rule-based high-value transaction alerts.
- MongoDB transaction migration and indexing.
- MongoDB aggregation for flagged-account analysis.
- Hourly transaction activity analysis.
- Interactive Streamlit dashboard.

## Dataset

The `datasets` folder contains seven CSV files:

- customers.csv
- branches.csv
- account_types.csv
- accounts.csv
- transactions.csv
- loans.csv
- transaction_flags.csv

The project uses sample educational banking data. Monitoring alerts are rule-based indicators and do not establish confirmed fraud.

## Project Folder Structure

```text
BankLedger-Project/
│
├── datasets/
├── app.py
├── BankLedger_Project.ipynb
├── schema.sql
├── data.sql
├── queries.sql
├── BankLedger_All_SQL_Backup.sql
├── Database_Design_and_Normalization.md
└── README.md
```

## How to Run

1. Install Python and the required libraries.
2. Set up MySQL and create the BankLedger database.
3. Configure your database credentials securely.
4. Open and run `BankLedger_Project.ipynb` in Jupyter Notebook.
5. Run the Streamlit dashboard:

```bash
py -m streamlit run app.py
```

Configure MongoDB Atlas credentials separately before running MongoDB-related notebook sections.

## Dashboard

The Streamlit dashboard provides:

- Banking overview
- Transactions
- Risk monitoring
- Analytics
- Database health

## Project Purpose

This project demonstrates practical skills in relational database management, SQL programming, Python-based data analysis, NoSQL databases, transaction monitoring, and dashboard development.

**Project:** BankLedger  
**Domain:** Banking and Financial Analytics  
**Author:** Ketan Balbhadra Sharma
