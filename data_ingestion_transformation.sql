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

-- Creating indexes to improve query performance in 'transactions' table
CREATE INDEX emails
ON transactions(email_address);

-- Checking the newly created index
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'transactions';

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

-- Exporting the transactions table as CSV before we proceed with EDA in Python
COPY (SELECT * FROM transactions) TO 'D:\\GitHub Projects\\airline-fraud-radar\\txns_cleaned.csv' WITH (FORMAT csv, HEADER true);

-------------------------------------------------
--- Fraud insights using SQL Window functions---
-------------------------------------------------

-- Velocity based fraud detection by checking multiple transactions made using the same ip_address with a time difference of less than 15 minutes between transactions
WITH repeating_ips AS(
	SELECT ip_address
	FROM transactions
	GROUP BY ip_address
	HAVING COUNT(*) > 1
),

time_diff AS (
	SELECT 
		*,
		LAG(timestamp, 1) OVER(PARTITION BY ip_address ORDER BY timestamp) AS prev_timestamp
	FROM transactions
)

SELECT 
	payment_id,
	ip_address,
	prev_timestamp
FROM time_diff
WHERE ip_address IN (SELECT ip_address FROM repeating_ips) AND (timestamp - prev_timestamp <= INTERVAL '00:15:00')
ORDER BY ip_address, timestamp;

-- Calculating weekly fraud percentage along with the total revenue 
SELECT
	DATE_TRUNC('week', timestamp) AS txn_week,
	COUNT(payment_id) AS total_txns,
	SUM(is_fraud) AS fraud_txns, 
	SUM(amount) AS total_revenue,
	SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END) AS fraud_loss,
	ROUND((SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END)) * 100 / SUM(amount), 2) AS fraud_loss_percentage
FROM transactions
GROUP BY DATE_TRUNC('week', timestamp)
ORDER BY txn_week;

-- Comparing total fraud loss amount vs total chargeback amount
SELECT 
	SUM(CASE WHEN t.is_fraud = 1 THEN t.amount ELSE 0 END) AS fraud_loss,
	SUM(c.amount) AS chargeback_loss
FROM transactions t
JOIN chargebacks c
	ON t.payment_id = c.payment_id
