/*
-------data initialization starts. Run this part of code before executing queries.------
*/
if not exists (select * from sysobjects where name='sales' and xtype='U')
    CREATE TABLE sales (
	"customer_id" VARCHAR(1),
	"order_date" DATE,
	"product_id" INTEGER
	);
GO

if not exists (select * from sysobjects where name='menu' and xtype='U')
    CREATE TABLE menu (
	"product_id" INTEGER,
	"product_name" VARCHAR(5),
	"price" INTEGER
	);
GO

if not exists (select * from sysobjects where name='members' and xtype='U')
	CREATE TABLE members (
	"customer_id" VARCHAR(1),
	"join_date" DATE
	);
GO

TRUNCATE TABLE sales;
GO

TRUNCATE TABLE menu;
GO

TRUNCATE TABLE members;
GO

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

INSERT INTO menu
  ("product_id", "product_name", "price") 
  VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

INSERT INTO members
  ("customer_id", "join_date")
	VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  /*
-------data initialization ends. Run this part of code before executing queries.------
*/


--1./What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(price) AS amt_spent FROM 
dbo.sales AS sales
INNER JOIN
dbo.menu menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY amt_spent DESC;

--2./How many days has each customer visited the restaurant?--
SELECT sales.customer_id, COUNT(DISTINCT order_date) visit_times 
FROM dbo.sales AS sales 
GROUP BY sales.customer_id;

--3./What was the first item from the menu purchased by each customer?
SELECT DISTINCT 
customer_id, 
m.product_name 
FROM sales s 
INNER JOIN menu m ON m.product_id = s.product_id
WHERE s.order_date = 
(
	SELECT MIN(order_date) FROM sales t
	WHERE t.customer_id = s.customer_id
);

--4./ Most popular product and number of times it is bought by all customers
SELECT 
product_name, 
purchase_times 
FROM menu m INNER JOIN
(
	SELECT TOP 1 s.product_id, count(s.product_id) as purchase_times
	FROM sales s GROUP BY s.product_id
	Order by COUNT(s.product_id) DESC
) 
AS most_popular_prod 
ON m.product_id = most_popular_prod.product_id;

--5./ Which item was the most popular for each customer?
SELECT 
customer_id, 
product_name, 
purchased_times FROM (
	SELECT 
	product_id, 
	customer_id, 
	COUNT(product_id) AS purchased_times, 
	RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) most_popular
	FROM sales
	GROUP BY product_id, customer_id 
) 
AS most_popular_prod_for_each_cus 
INNER JOIN menu m 
ON most_popular_prod_for_each_cus.product_id = m.product_id 
WHERE most_popular_prod_for_each_cus.most_popular = 1;

--6./ Which item was purchased first by the customer after they became a member?
SELECT customer_id AS customer, 
product_name AS 'fisrt purchased item after join' 
FROM (
	SELECT m.customer_id, 
	join_date, 
	product_id, 
	order_date, 
	RANK() OVER (PARTITION BY m.customer_id ORDER BY order_date) order_date_ranking
	FROM members m 
	INNER JOIN sales s
	ON m.customer_id = s.customer_id
	WHERE order_date > join_date
) AS first_item_purchase_after_member 
INNER JOIN menu m
ON first_item_purchase_after_member.product_id = m.product_id
WHERE first_item_purchase_after_member.order_date_ranking = 1;

--7./ Which item was purchased just before the customer became a member?
SELECT customer_id AS customer, 
product_name AS 'last purchased item before join' 
FROM (
	SELECT m.customer_id, 
	join_date, 
	product_id, 
	order_date, 
	RANK() OVER (PARTITION BY m.customer_id ORDER BY order_date DESC) order_date_ranking
	FROM members m 
	INNER JOIN sales s
	ON m.customer_id = s.customer_id
	WHERE order_date < join_date
) AS first_item_purchase_after_member 
INNER JOIN menu m
ON first_item_purchase_after_member.product_id = m.product_id
WHERE first_item_purchase_after_member.order_date_ranking = 1;

--8./What is the total items and amount spent for each member before they became a member?
SELECT customer_id AS customer, 
COUNT(DISTINCT m.product_name) 'total_items_count', 
SUM(price) AS 'amt_spend_before_join' 
FROM (
	SELECT m.customer_id, 
	join_date, product_id, 
	order_date
	FROM members m 
	INNER JOIN sales s
	ON m.customer_id = s.customer_id
	WHERE order_date < join_date
) AS first_item_purchase_after_member 
INNER JOIN menu m
ON first_item_purchase_after_member.product_id = m.product_id
GROUP BY customer_id;

--9./If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, 
SUM (
CASE 
	WHEN m.product_name = 'sushi' THEN 20 * m.price
	ELSE 10 * m.price
END) total_points
FROM sales
INNER JOIN menu m
ON sales.product_id = m.product_id
GROUP BY customer_id;

--10./In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT sales.customer_id,
SUM(
CASE 
	WHEN order_date between join_date AND DATEADD(DAY,6,join_date) THEN 20 * m.price
	ELSE 
		CASE 
			WHEN m.product_name = 'sushi' THEN m.price * 20
			ELSE m.price * 10
		END
END) AS total_points
FROM sales
INNER JOIN 
members mem 
ON sales.customer_id = mem.customer_id
INNER JOIN
menu m 
ON sales.product_id = m.product_id
WHERE MONTH(order_date) = 1
GROUP BY sales.customer_id;

--Bonus question 1
WITH customer_order_when_member 
AS 
(
	SELECT s.customer_id, s.order_date, m.product_name, m.price,
	( 
	CASE 
		WHEN EXISTS(SELECT x.join_date FROM members x WHERE x.join_date <= s.order_date AND s.customer_id = x.customer_id) THEN 'Y'
		ELSE 'N'
	END
	) member FROM Sales s
	LEFT JOIN members mem
	ON s.customer_id = mem.customer_id
	INNER JOIN menu m
	ON s.product_id = m.product_id
)
SELECT * FROM customer_order_when_member;

--Bonus question 2. Done
WITH customer_order_when_member 
AS 
(
	SELECT s.customer_id, s.order_date, m.product_name, m.price,
	( 
	CASE 
		WHEN EXISTS(SELECT x.join_date FROM members x WHERE x.join_date <= s.order_date AND x.customer_id = s.customer_id) THEN 'Y'
		ELSE 'N'
	END
	) member FROM Sales s
	LEFT JOIN members mem
	ON s.customer_id = mem.customer_id
	INNER JOIN menu m
	ON s.product_id = m.product_id
)
SELECT *, 
(CASE
	WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	ELSE NULL
END
) AS ranking
FROM customer_order_when_member;

