CREATE SCHEMA pizza_runner;
USE pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  # DATA CLEANING
-- to change null and empty rows in the cancellation column to Not Cancelled
UPDATE runner_orders set cancellation='Not Cancelled'
WHERE cancellation != 'Restaurant Cancellation' AND cancellation != 'Customer Cancellation' OR cancellation IS NULL;

-- to change null and empty rows in the exclusions column to None
UPDATE customer_orders set exclusions='None'
WHERE exclusions = 'null' OR exclusions = '' OR exclusions IS NULL;

-- to change null and empty rows in the extras column to None
UPDATE customer_orders set extras='None'
WHERE extras = 'null' OR extras = '' OR extras IS NULL;

-- to clean the spaces and remove the 'km' in the distance column
UPDATE runner_orders SET distance = REPLACE(distance, ' ', '');
UPDATE runner_orders SET distance = REPLACE(distance, distance, LEFT(distance, LENGTH(distance) - 2));
UPDATE runner_orders SET distance = 0
WHERE distance = '' OR distance = 'nu';

-- to clean the spaces and remove the 'mins' and 'minutes' in the duration column
UPDATE runner_orders SET duration = REPLACE(duration, duration, LEFT(duration, 2));
UPDATE runner_orders SET duration = 0
WHERE duration = 'nu';

-- to remove extra spaces in the toppings column
UPDATE pizza_recipes SET toppings = REPLACE(toppings, ' ', '');

-- to remove extra spaces in the extras column
UPDATE customer_orders SET extras = REPLACE(extras, ' ', '');

-- to remove extra spaces in the exclusions column
UPDATE customer_orders SET exclusions = REPLACE(exclusions, ' ', '');

# PART A
# How many pizzas were ordered?
SELECT COUNT(order_id) as no_ordered
FROM customer_orders;

# How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) as unique_customer_orders
FROM customer_orders;

# How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(cancellation) as sus_deliveries
FROM runner_orders
WHERE cancellation = 'Not Cancelled'
GROUP BY 1
ORDER BY 2 DESC;

# How many of each type of pizza was delivered?
SELECT c.pizza_id, p.pizza_name, COUNT(c.pizza_id) as no_delivered
FROM runner_orders as r
JOIN customer_orders as c 
ON c.order_id = r.order_id
JOIN pizza_names as p
ON p.pizza_id = c.pizza_id
WHERE r.cancellation = 'Not Cancelled'
GROUP BY 1
ORDER BY 3 DESC;

# How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, 
COUNT(CASE WHEN pizza_id = 1 THEN pizza_id END) AS 'Meatlovers',
COUNT(CASE WHEN pizza_id = 2 THEN pizza_id END) AS 'Vegetarian'
FROM customer_orders
GROUP BY 1;

# What was the maximum number of pizzas delivered in a single order?
SELECT c.order_id, COUNT(c.pizza_id) as max_delivered
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled' 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

# For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH T1 AS
(SELECT c.order_id, c.pizza_id, c.exclusions, c.extras
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled')

SELECT 
COUNT(CASE WHEN exclusions = 'None' AND extras = 'None' THEN pizza_id END) AS without_changes,
COUNT(CASE WHEN exclusions != 'None' OR extras != 'None' THEN pizza_id END) AS with_changes
FROM T1;

# How many pizzas were delivered that had both exclusions and extras?
WITH T1 AS
(SELECT c.order_id, c.pizza_id, c.exclusions, c.extras
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled')

SELECT 
COUNT(CASE WHEN exclusions != 'None' AND extras != 'None' THEN pizza_id END) AS both_changes
FROM T1;

# What was the total volume of pizzas ordered for each hour of the day?
SELECT * FROM customer_orders;
SELECT HOUR(order_time) hour_of_day, COUNT(pizza_id) no_of_pizzas
FROM customer_orders
GROUP BY 1
ORDER BY 2 DESC;

# What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) day_of_week, COUNT(pizza_id) no_of_pizzas
FROM customer_orders
GROUP BY 1
ORDER BY 2 DESC;

#PART B
# How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT WEEK(registration_date) as week_number,
COUNT(runner_id) runners_signed
FROM runners
GROUP BY WEEK(registration_date)
ORDER BY WEEK(registration_date);

# What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT CONCAT(AVG(duration), ' minutes') AS avg_pickup_time
FROM runner_orders
WHERE duration != 0;

# Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT c.order_id, COUNT(c.pizza_id) as no_delivered, r.duration
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled'
GROUP BY 1
ORDER BY 2 DESC;

# What was the average distance travelled for each customer?
SELECT c.customer_id, CONCAT(ROUND(AVG(r.duration), 2), ' km') as avg_distance
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled'
GROUP BY 1
ORDER BY 1;

# What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) as time_diff
FROM runner_orders
WHERE duration != 0;

# What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT r.order_id, COUNT(c.pizza_id), r.distance, r.duration, CONCAT(ROUND((r.distance/(r.duration/60)), 2), ' km/h') as avg_speed
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE distance != 0
GROUP BY 1
ORDER BY 5 DESC;

# What is the successful delivery percentage for each runner?
SELECT runner_id, 
CONCAT(
	ROUND(
		(COUNT(CASE WHEN cancellation = 'Not Cancelled' THEN order_id END)/COUNT(order_id)) *100.0), '%') AS delivery_percent
FROM runner_orders
GROUP BY 1;

#PART C
# What are the standard ingredients for each pizza?
SELECT p.pizza_name, GROUP_CONCAT(DISTINCT(t.topping_name)) AS standard_ingredients
FROM pizza_names p
JOIN pizza_recipes r ON p.pizza_id = r.pizza_id
JOIN pizza_toppings t ON FIND_IN_SET(t.topping_id, r.toppings)
GROUP BY p.pizza_name;

# What was the most commonly added extra?
SELECT topping_name AS most_common_extra,
    COUNT(*) AS extra_count
FROM customer_orders
JOIN pizza_toppings ON FIND_IN_SET(topping_id, extras)
WHERE extras != 'None'
GROUP BY topping_id
ORDER BY extra_count DESC
LIMIT 1;

# What was the most common exclusion?
SELECT topping_name AS most_common_exclusion,
    COUNT(*) AS exclusion_count
FROM customer_orders
JOIN pizza_toppings ON FIND_IN_SET(topping_id, exclusions)
WHERE exclusions != 'None'
GROUP BY topping_id
ORDER BY exclusion_count DESC
LIMIT 1;

# Generate an order item for each record in the customer_orders
WITH T1 AS 
(SELECT o.order_id,
p.pizza_name,
CASE WHEN o.exclusions != 'None' THEN
	CONCAT(' - Exclude ', GROUP_CONCAT(DISTINCT t.topping_name SEPARATOR ', '))
	ELSE '' END as A
FROM customer_orders o
JOIN pizza_names p ON o.pizza_id = p.pizza_id
LEFT JOIN pizza_toppings t ON FIND_IN_SET(t.topping_id, o.exclusions)
GROUP BY o.order_id, p.pizza_name, o.exclusions, o.extras),

T2 AS 
(SELECT o.order_id,
CASE WHEN o.extras != 'None' THEN
	CONCAT(' - Extra ', GROUP_CONCAT(DISTINCT t.topping_name SEPARATOR ', '))
	ELSE '' END AS B
FROM customer_orders o
JOIN pizza_names p ON o.pizza_id = p.pizza_id
LEFT JOIN pizza_toppings t ON FIND_IN_SET(t.topping_id, o.extras)
GROUP BY o.order_id, p.pizza_name, o.exclusions, o.extras)

SELECT T1.order_id, 
CONCAT(T1.pizza_name, T1.A, T2.B) AS order_list
FROM T1
JOIN T2 ON T1.order_id = T2.order_id
GROUP BY 1, T1.pizza_name;

SELECT * FROM customer_orders;
SELECT * FROM pizza_toppings;

# Generate an alphabetically ordered comma separated ingredient list for each pizza order 
# from the customer_orders table and add a 2x in front of any relevant ingredients
-- new correction
SELECT
    co.order_id,
    GROUP_CONCAT(
        CASE
            WHEN COUNT(pt.topping_id) > 1 THEN CONCAT(COUNT(pt.topping_id), 'x ', pt.topping_name)
            ELSE pt.topping_name
        END
        ORDER BY pt.topping_name ASC
        SEPARATOR ', '
    ) AS ingredient_list
FROM
    customer_orders co
JOIN
    pizza_names pn ON co.pizza_id = pn.pizza_id
LEFT JOIN
    pizza_recipes pr ON co.pizza_id = pr.pizza_id
LEFT JOIN
    pizza_toppings pt ON FIND_IN_SET(pt.topping_id, pr.toppings)
LEFT JOIN
    pizza_toppings pt_ex ON FIND_IN_SET(pt_ex.topping_id, co.exclusions)
LEFT JOIN
    pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, co.extras)
WHERE
    pt_ex.topping_id = 'None' AND pt.topping_id != 'None'
    AND (pt_extras.topping_id IS NULL OR FIND_IN_SET(pt.topping_id, co.extras))
GROUP BY
    co.order_id;


SELECT
    co.order_id,
    GROUP_CONCAT(
        CASE
            WHEN topping_count > 1 THEN CONCAT(topping_count, 'x ', pt.topping_name)
            ELSE pt.topping_name
        END
        ORDER BY pt.topping_name ASC
        SEPARATOR ', '
    ) AS ingredient_list
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
LEFT JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
LEFT JOIN pizza_toppings pt ON FIND_IN_SET(pt.topping_id, pr.toppings)
LEFT JOIN (
    SELECT
        o.order_id,
        pt.topping_id,
        COUNT(pt.topping_id) AS topping_count
    FROM
        customer_orders o
    LEFT JOIN
        pizza_recipes pr ON o.pizza_id = pr.pizza_id
    LEFT JOIN
        pizza_toppings pt ON FIND_IN_SET(pt.topping_id, pr.toppings)
    GROUP BY
        o.order_id, pt.topping_id
) AS topping_counts ON co.order_id = topping_counts.order_id AND pt.topping_id = topping_counts.topping_id
LEFT JOIN
    pizza_toppings pt_ex ON FIND_IN_SET(pt_ex.topping_id, co.exclusions)
LEFT JOIN
    pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, co.extras)
WHERE
    pt_ex.topping_id IS NULL AND pt_extras.topping_id IS NULL
GROUP BY
    co.order_id;




SELECT
    order_id,
    TRIM(BOTH ',' FROM ingredient_list) AS cleaned_ingredient_list
FROM
(SELECT c.order_id,
GROUP_CONCAT(CASE WHEN t.topping_id IS NOT NULL AND c.exclusions NOT LIKE CONCAT('%', t.topping_id, '%') THEN
	CONCAT(
		CASE WHEN c.extras LIKE CONCAT('%', t.topping_id, '%') THEN '2x ' ELSE '' END,
		t.topping_name)
            ELSE ''
        END
        ORDER BY t.topping_name ASC
        SEPARATOR ', '
    ) AS ingredient_list
FROM customer_orders c
LEFT JOIN pizza_names p ON c.pizza_id = p.pizza_id
LEFT JOIN pizza_recipes r ON c.pizza_id = r.pizza_id
LEFT JOIN pizza_toppings t ON FIND_IN_SET(t.topping_id, r.toppings)
GROUP BY c.order_id) T1;


# What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT topping_name AS ingredient,
    COUNT(CASE WHEN c.exclusions != 'None' OR c.extras != 'None' THEN pizza_id END) AS ingredient_count
FROM customer_orders as c
JOIN runner_orders as r
JOIN pizza_recipes as pr
JOIN pizza_toppings 
ON FIND_IN_SET(topping_id, extras) OR FIND_IN_SET(topping_id, exclusions)
WHERE extras != 'None' OR exclusions != 'None' AND r.cancellation = 'Not Cancelled'
GROUP BY 1
ORDER BY ingredient_count DESC;


#PART D
# If a Meat Lovers pizza costs $12 and Vegetarian costs $10 
# and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT CONCAT('$', 
		SUM(CASE WHEN c.pizza_id = 1 THEN 12
		WHEN c.pizza_id = 2 THEN 10 END)) AS total_earnings
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled';

# What if there was an additional $1 charge for any pizza extras?
SELECT CONCAT('$', (SELECT  
		SUM(CASE WHEN c.pizza_id = 1 THEN 12
		WHEN c.pizza_id = 2 THEN 10 END) AS total_earnings
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled') + 
(SELECT
    COUNT(*) AS extra_count
FROM customer_orders
JOIN pizza_toppings ON FIND_IN_SET(topping_id, extras)
WHERE extras != 'None')) AS gross_earnings;

# Ratings table
DROP TABLE IF EXISTS runner_ratings;

CREATE TABLE runner_ratings AS
SELECT order_id,
	   runner_id,
       CASE WHEN cancellation != 'Not Cancelled' THEN '-' 
       WHEN duration <= 15 THEN 5
       WHEN duration >15 AND duration <= 25 THEN 4
       WHEN duration >25 AND duration <= 35 THEN 3
       WHEN duration >35 AND duration <= 45 THEN 2
       WHEN duration >45 THEN 1
	END AS ratings
FROM runner_orders;

SELECT * FROM runner_ratings;
# Using your newly generated table - can you join all of the information 
-- together to form a table which has the following information for successful deliveries?
-- customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order and pickup
-- Delivery duration, Average speed, Total number of pizzas

SELECT c.customer_id, r.order_id, r.runner_id,
rr.ratings,
c.order_time,
r.pickup_time,
TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) AS processing_time,
r.duration,
ROUND((r.distance/(r.duration/60)), 2) AS avg_speed,
COUNT(c.pizza_id) as pizzas_delivered
FROM customer_orders c
JOIN runner_orders r
ON c.order_id = r.order_id
JOIN runner_ratings rr
ON r.runner_id = rr.runner_id AND r.order_id = rr.order_id
WHERE rr.ratings != '-'
GROUP BY 2
ORDER BY 2;

# If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
# each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT CONCAT('$', ROUND(total_earnings - total_runner_pay, 2)) AS net_earnings
FROM
(SELECT SUM(CASE WHEN c.pizza_id = 1 THEN 12
		WHEN c.pizza_id = 2 THEN 10 END) AS total_earnings,
	ROUND((SUM(r.distance) * 0.30),2) AS total_runner_pay
FROM customer_orders as c
JOIN runner_orders as r
ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Cancelled') T1;


# PART E
# Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
SELECT * from pizza_toppings;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_names;

INSERT INTO pizza_names
VALUES (3, 'Supreme');
SELECT * FROM pizza_names;

INSERT INTO pizza_recipes 
SELECT p.pizza_id, GROUP_CONCAT(t.topping_id)
FROM pizza_names as p, pizza_toppings as t
WHERE p.pizza_name = 'Supreme';
SELECT * FROM pizza_recipes;
