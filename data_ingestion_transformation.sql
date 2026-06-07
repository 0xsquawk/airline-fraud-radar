-------------------------------------------------
--- Data Engineering & Pipeline Infrastructure---
-------------------------------------------------

-- Creating a new database
CREATE DATABASE payment_fraud;

-- Creating tables under the database and defining data types
CREATE TABLE transactions (
	payment_id VARCHAR(255) PRIMARY KEY,
	timestamp TIMESTAMP,
	customer_name VARCHAR(255),
	email_address VARCHAR(255),
	amount NUMERIC(10,2),
	currency VARCHAR(10),
	card_type VARCHAR(50),
	masked_cc VARCHAR(50),
	auth_code VARCHAR(50),
	ip_address INET,
	PNR VARCHAR(50),
	MRN VARCHAR(50),
	is_fraud INTEGER
);

CREATE TABLE chargebacks (
	chargeback_id VARCHAR(255) PRIMARY KEY,
	payment_id VARCHAR(255) REFERENCES transactions(payment_id),
	chargeback_date TIMESTAMP,
	acquiring_bank VARCHAR(50),
	payment_processor VARCHAR(50),
	chargeback_reason_code VARCHAR(50),
	amount NUMERIC(10,2),
	currency VARCHAR(50)
);

CREATE TABLE blacklist_data (
	entity_value VARCHAR(255),
	entity_type VARCHAR(255),
	source VARCHAR(50),
	date_added TIMESTAMP
)

-- Importing data from source files into SQL tables
COPY transactions FROM 'D:\\Project_Test\\payment_fraud_analytics_aviation\\Gemini Gen\table1_transactions.csv' WITH (FORMAT csv, HEADER true);

COPY chargebacks FROM 'D:\\Project_Test\\payment_fraud_analytics_aviation\\Gemini Gen\\table2_chargebacks.csv' WITH (FORMAT csv, HEADER true);

COPY blacklist_data FROM 'D:\\Project_Test\\payment_fraud_analytics_aviation\\Gemini Gen\\table3_blacklist.csv' WITH (FORMAT csv, HEADER true)

-------------------------------------------------
--- Data integrity check and transformation---
-------------------------------------------------

-- Checking if any NULL values are present in the table
SELECT *
FROM transactions
WHERE transactions IS NULL;

SELECT *
FROM chargebacks
WHERE chargebacks IS NULL;

SELECT *
FROM blacklist_data
WHERE blacklist_data IS NULL;

-- Checking for duplicate values even though we have already declared 'payment_id' as primary key
SELECT COUNT(*), payment_id
FROM transactions
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- Adding a new column for last four digits of card number
ALTER TABLE transactions 
ADD COLUMN card_last_four VARCHAR(4) 
GENERATED ALWAYS AS (RIGHT(masked_cc, 4)) STORED;

-- Creating indexes to improve query performance across 'transactions' and 'chargebacks' tables
CREATE INDEX txn_id
ON transactions(payment_id);

CREATE INDEX emails
ON transactions(email_address);

CREATE INDEX cbk_id
ON chargebacks(chargeback_id);

-- Checking the newly created indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'transactions' OR tablename = 'chargebacks';
