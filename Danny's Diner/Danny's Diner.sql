CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', 10),
  ('2', 'curry', 15),
  ('3', 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

# amount spent by each customer at the restaurant
SELECT * FROM sales;
SELECT * FROM menu;

SELECT s.customer_id customer, CONCAT('$', SUM(m.price)) total_spend
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;

# How many days has each customer visited the restaurant?
SELECT customer_id customer, CONCAT(COUNT(DISTINCT order_date), ' ', 'days') visit_date
FROM sales
GROUP BY 1
ORDER BY 2 DESC;


# What was the first item from the menu purchased by each customer?
SELECT customer, product
FROM 
(SELECT s.customer_id customer,
s.order_date, m.product_name as product, 
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS row_num
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id) temp_table
WHERE row_num = 1;

# What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) no_of_purchases, CONCAT('$', SUM(m.price)) total_sales
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.product_id
ORDER BY 3 DESC
LIMIT 1;

# Which item was the most popular for each customer?
SELECT customer, product_name, no_of_purchases FROM
(SELECT s.customer_id customer, m.product_name, COUNT(s.product_id) no_of_purchases,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS pop_purchase
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY 1, s.product_id) T1
WHERE pop_purchase = 1;

# Which item was purchased first by the customer after they became a member?
SELECT customer, product_name
FROM
(SELECT s.customer_id customer, m.product_name, s.order_date,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS row_num
FROM menu as m
JOIN sales as s
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date <= s.order_date
ORDER BY 1, 3) T2
WHERE row_num = 1; 

# Which item was purchased just before the customer became a member?
SELECT customer, product_name
FROM
(SELECT s.customer_id customer, m.product_name, s.order_date,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS row_num
FROM menu as m
JOIN sales as s
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date > s.order_date
ORDER BY 1, 3) T3
WHERE row_num = 1;

# What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id customer, COUNT(s.product_id) purchases, CONCAT('$', SUM(m.price)) amt_spent
FROM menu as m
JOIN sales as s
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date > s.order_date
GROUP BY 1
ORDER BY 2,3 DESC;

# If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer, CONCAT(SUM(points), ' ', 'points') total_tally
FROM
(SELECT s.customer_id customer, s.product_id, m.product_name, m.price,
CASE WHEN m.product_name = 'sushi' THEN price * 20
ELSE price * 10 END AS points
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id) T4
GROUP BY customer;

#In the first week after a customer joins the program (including their join date) 
#they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer, CONCAT(SUM(point_tally), ' points') total_tally
FROM
(SELECT s.customer_id customer, m.product_name, s.order_date,
CASE WHEN s.order_date < (mem.join_date + 7) THEN m.price * 20
ELSE m.price * 10 END AS point_tally
FROM menu as m
JOIN sales as s
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date < s.order_date AND month(s.order_date) = 1
ORDER BY 1, 3)T5
GROUP BY customer
ORDER BY customer;

#Recreate table; Bonus Question 1
SELECT s.customer_id customer, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= mem.join_date AND s.customer_id = mem.customer_id THEN 'Y'
ELSE 'N' END AS member
FROM menu as m
LEFT JOIN sales as s
ON s.product_id = m.product_id
LEFT JOIN members as mem
ON mem.customer_id = s.customer_id
ORDER BY 1, 2;

# Bonus Question 2
SELECT s.customer_id customer, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= mem.join_date AND s.customer_id = mem.customer_id THEN 'Y'
ELSE 'N' END AS member,
CASE WHEN s.order_date >= mem.join_date AND s.customer_id = mem.customer_id 
THEN DENSE_RANK() OVER(PARTITION BY s.customer_id, order_date >=mem.join_date ORDER BY s.order_date) 
ELSE 'null' END AS ranking
FROM menu as m
LEFT JOIN sales as s
ON s.product_id = m.product_id
LEFT JOIN members as mem
ON mem.customer_id = s.customer_id
ORDER BY 1, 2;