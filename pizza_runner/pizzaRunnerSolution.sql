USE master;
GO

--remove active connections from food journal db 
ALTER DATABASE pizza_runner
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

--drop table if it exists
DROP DATABASE IF exists pizza_runner;
GO

--create new database
CREATE DATABASE pizza_runner

--set multi user and use db
ALTER DATABASE pizza_runner
SET MULTI_USER;
GO

USE pizza_runner
--DROP DATABASE IF EXISTS pizza_runner;
--GO

--CREATE DATABASE pizza_runner;
--GO

--after running the first 2 statements, 
--choose pizza_runner (if use msql management studio)
--BEFORE RUNNING THE STATEMENTS BELOW

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INT,
  registration_date DATETIME
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
  order_id INT,
  customer_id INT,
  pizza_id INT,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time SMALLDATETIME
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
  order_id INT,
  runner_id INT,
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
  pizza_id INT,
  pizza_name VARCHAR(50)
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings VARCHAR(100)
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INT,
  topping_name VARCHAR(50)
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

UPDATE runner_orders 
SET cancellation = '' WHERE cancellation IS NULL
OR cancellation = 'null';

 --How many pizzas were ordered?
SELECT COUNT(pizza_id) AS numPizzaOrdered
FROM dbo.customer_orders;

--How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS numUniqueOrder FROM dbo.customer_orders;

--How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successfulOrderCount
FROM dbo.runner_orders 
WHERE cancellation IS NULL OR cancellation IN ('null','')
GROUP BY runner_id;

--How many of each type of pizza was delivered?
SELECT pizza_name, COUNT(ro.order_id) FROM 
runner_orders ro 
INNER JOIN customer_orders co
ON ro.order_id = co.order_id
INNER JOIN pizza_names pn
ON co.pizza_id= pn.pizza_id
WHERE cancellation IS NULL OR cancellation IN ('null','')
GROUP BY pizza_name;

--How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, 
	SUM(
	CASE 
		WHEN co.pizza_id = 1 THEN 1
		ELSE 0
	END) MeatLovers,
	SUM(
	CASE 
		WHEN co.pizza_id = 2 THEN 1
		ELSE 0
	END
	) Vegetarians
FROM customer_orders co
GROUP BY customer_id;

--What was the maximum number of pizzas delivered in a single order?
WITH successfulOrders AS(
SELECT order_id AS deliveredOrderId
FROM dbo.runner_orders 
WHERE cancellation IS NULL OR cancellation IN ('null','')
),
orderAndPizzaCount AS(
SELECT order_id, 
COUNT(pizza_id) AS pizzaDeliveredCount 
FROM customer_orders co 
WHERE EXISTS 
(
	SELECT TOP 1 * 
	FROM successfulOrders so 
	WHERE so.deliveredOrderId = co.order_id
)
GROUP BY order_id
)

SELECT TOP 1 pizzaDeliveredCount
FROM orderAndPizzaCount
ORDER BY pizzaDeliveredCount DESC;

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
UPDATE dbo.customer_orders SET
exclusions = NULL
WHERE exclusions IN ('null', 'NaN', '');

UPDATE dbo.customer_orders SET
extras = NULL
WHERE extras IN ('null', 'NaN', '');


WITH customer_order_status_count AS 
(
SELECT 
	customer_id, 
	pizza_id,
	exclusions,
	extras
	FROM dbo.customer_orders co
	LEFT JOIN runner_orders ro ON co.order_id = ro.order_id
	WHERE ro.cancellation NOT IN ('Customer Cancellation', 'Restaurant Cancellation')
)
SELECT 
customer_id, 
SUM (
CASE
	WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0
END) orderWithChanges,
SUM (
CASE
	WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0
END) orderWithoutChanges 
FROM customer_order_status_count GROUP BY customer_id ORDER BY customer_id;

--How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(pizza_id) pizza_with_both_extras_exclusions 
FROM customer_orders co 
WHERE co.exclusions IS NOT NULL AND co.extras IS NOT NULL;

SELECT 
DATEPART(HOUR, co.order_time) AS TimeWithMilliseconds,
COUNT(order_id)
FROM customer_orders co
GROUP BY DATEPART(HOUR, co.order_time);
