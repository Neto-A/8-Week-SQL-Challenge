-- PART A
-- How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id)
FROM customer_nodes;

-- What is the number of nodes per region?
SELECT r.region_name, COUNT(DISTINCT n.node_id)
FROM regions as r
JOIN customer_nodes as n
ON r.region_id = n.region_id
GROUP BY 1
ORDER BY 2;


SELECT r.region_name, COUNT(r.region_name)
FROM regions as r
JOIN customer_nodes as n
ON r.region_id = n.region_id
GROUP BY 1
ORDER BY 2 DESC;

-- How many customers are allocated to each region?
SELECT r.region_name, COUNT(DISTINCT n.customer_id)
FROM regions as r
JOIN customer_nodes as n
ON r.region_id = n.region_id
GROUP BY 1
ORDER BY 2 DESC;

-- How many days on average are customers reallocated to a different node?
SELECT * FROM customer_nodes;
SELECT CONCAT(CEIL(AVG(day_to_change)), ' days') as avg_day_to_change
FROM
(SELECT customer_id, start_date, node_id,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date,
CASE WHEN LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) IS NOT NULL 
THEN (LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) - start_date) ELSE 0 END AS day_to_change
FROM customer_nodes) T1;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH node_changes AS
(SELECT n.customer_id, n.start_date, n.node_id, r.region_name,
LEAD(n.start_date) OVER (PARTITION BY n.customer_id ORDER BY n.start_date) AS row_num,
CASE WHEN LEAD(n.start_date) OVER (PARTITION BY n.customer_id ORDER BY n.start_date) IS NOT NULL 
	THEN (LEAD(n.start_date) OVER (PARTITION BY n.customer_id ORDER BY n.start_date) - n.start_date) 
		ELSE 0 END AS day_to_change
FROM customer_nodes as n
JOIN regions as r
ON n.region_id = r.region_id)

SELECT region_name,
 PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY day_to_change) AS median,
 PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY day_to_change) AS percentile_85,
 PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY day_to_change) AS percentile_95
 FROM node_changes
GROUP BY 1;


-- PART B
-- What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(DISTINCT customer_id) AS unique_count,
SUM(txn_amount) AS total
FROM customer_transactions
GROUP BY 1
ORDER BY 2 DESC;

-- What is the average total historical deposit counts and amounts for all customers?
SELECT ROUND(AVG(deposit_count)) AS avg_deposit_count, 
ROUND(AVG(deposit_amount)) AS avg_deposit_amount
FROM
(SELECT customer_id, COUNT(txn_type) AS deposit_count, SUM(txn_amount) AS deposit_amount
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id) deposit_txns;

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH type_counts AS
(SELECT customer_id, 
COUNT(CASE WHEN txn_type = 'deposit' THEN customer_id END) AS deposit_count,
COUNT(CASE WHEN txn_type = 'purchase' THEN customer_id END) AS purchase_count,
COUNT(CASE WHEN txn_type = 'withdrawal' THEN customer_id END) AS withdrawal_count
FROM customer_transactions
GROUP BY customer_id)
SELECT TO_CHAR(c.txn_date, 'Month') as month_name,
CONCAT(COUNT(DISTINCT t.customer_id), ' customers') AS ret_customers
FROM type_counts t
JOIN customer_transactions c
ON t.customer_id = c.customer_id
WHERE t.deposit_count > 1 AND (t.purchase_count > 0 OR t.withdrawal_count > 0)
GROUP BY 1
ORDER BY 2 DESC;

-- What is the closing balance for each customer at the end of the month?
WITH customer_funds AS
(SELECT customer_id, TO_CHAR(txn_date, 'Month') as month_name,
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END) AS total_amount
FROM customer_transactions
GROUP BY customer_id, 2
ORDER BY 1)
SELECT customer_id, month_name,
SUM(total_amount) OVER(PARTITION BY customer_id ORDER BY month_name) AS closing_balance
FROM customer_funds;

-- What is the percentage of customers who increase their closing balance by more than 5%?


-- PART C
-- running customer balance column that includes the impact each transaction
WITH amounts AS
(SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, txn_type, txn_amount, 
CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS total_amount
FROM customer_transactions
ORDER BY customer_id)

SELECT customer_id, month_num, total_amount, 
SUM(total_amount) OVER (PARTITION BY customer_id, month_num 
	ORDER BY month_num ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			AS running_balance
FROM amounts;

-- customer balance at the end of each month
SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, 
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END) AS monthly_balance
FROM customer_transactions
GROUP BY 1, 2
ORDER BY customer_id
;

-- minimum, average and maximum values of the running balance for each customer
WITH amounts AS
(SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, txn_type, txn_amount, 
CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS total_amount
FROM customer_transactions
ORDER BY customer_id),

balances AS 
(SELECT customer_id, month_num, total_amount, 
SUM(total_amount) OVER (PARTITION BY customer_id, month_num 
	ORDER BY month_num ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			AS running_balance
FROM amounts)

SELECT customer_id, 
MIN(running_balance) as min_bal, 
ROUND(AVG(running_balance),2) AS avg_bal, 
MAX(running_balance) AS max_bal
FROM balances
GROUP BY 1;

-- monthly allocation by amount
WITH amounts AS
(SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, 
 TO_CHAR(txn_date, 'Month') as month_name,
 txn_type, txn_amount, 
CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS total_amount
FROM customer_transactions
ORDER BY customer_id),

balances AS 
(SELECT customer_id, month_num, month_name, total_amount, 
SUM(total_amount) OVER (PARTITION BY customer_id, month_num 
	ORDER BY month_num ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			AS running_balance
FROM amounts),

allocations AS 
(SELECT *,
LAG(running_balance, 1) OVER(PARTITION BY customer_id 
   			ORDER BY customer_id, month_num) AS monthly_allocation
FROM balances)

SELECT month_num, month_name,
SUM(CASE WHEN monthly_allocation < 0 THEN 0 ELSE monthly_allocation END) AS total_allocation
FROM allocations
GROUP BY 1,2
ORDER BY 1,2;

-- allocation by average 
WITH amounts AS
(SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, 
 TO_CHAR(txn_date, 'Month') as month_name,
 txn_type, txn_amount, 
CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS total_amount
FROM customer_transactions
ORDER BY customer_id),

balances AS 
(SELECT customer_id, month_num, month_name, total_amount, 
SUM(total_amount) OVER (PARTITION BY customer_id, month_num 
	ORDER BY month_num ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			AS running_balance
FROM amounts),

avg_running AS
(SELECT customer_id, 
month_num, month_name,
ROUND(AVG(running_balance),2) AS avg_bal 
FROM balances
GROUP BY 1,2,3
ORDER BY 1)

SELECT month_num, month_name,
SUM(CASE WHEN avg_bal < 0 THEN 0 ELSE avg_bal END) AS total_allocation
FROM avg_running
GROUP BY 1,2
ORDER BY 1,2;

-- data updated real time
WITH amounts AS
(SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, 
 TO_CHAR(txn_date, 'Month') as month_name,
 txn_type, txn_amount, 
CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS total_amount
FROM customer_transactions
ORDER BY customer_id),

balances AS 
(SELECT customer_id, month_num, month_name, total_amount, 
SUM(total_amount) OVER (PARTITION BY customer_id, month_num 
	ORDER BY month_num ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			AS running_balance
FROM amounts)

SELECT month_num, month_name,
SUM(CASE WHEN running_balance < 0 THEN 0 ELSE running_balance END) AS total_allocation
FROM balances
GROUP BY 1,2
ORDER BY 1,2;

--PART D
-- allocation using interest rate of 6% pa
WITH monthly_balances AS
(SELECT customer_id, EXTRACT('Month' FROM txn_date) as month_num, 
 TO_CHAR(txn_date, 'Month') as month_name,
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END) AS monthly_balance
FROM customer_transactions
GROUP BY 1, 2, 3
ORDER BY customer_id),

interest_earned AS
(SELECT *,
ROUND(((monthly_balance * 6 * 1)/(100.0 * 12)),2) AS interest
FROM monthly_balances
GROUP BY customer_id, month_num, month_name, monthly_balance
ORDER BY customer_id, month_num, month_name),

total_earnings AS
(SELECT customer_id, month_num, month_name,
(monthly_balance + interest) AS earnings
FROM interest_earned
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3)

SELECT month_num, month_name,
SUM(CASE WHEN earnings < 0 THEN 0 ELSE earnings END) as allocation
FROM total_earnings
GROUP BY 1,2
ORDER BY 1,2;