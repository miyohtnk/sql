/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */
SELECT 
product_name || ', ' || COALESCE(product_size, '')|| ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

--row_number() option to select unique market dates per customer
SELECT market_date, customer_id,
row_number() OVER(PARTITION BY customer_id ORDER BY market_date ASC) as customer_visits
FROM (
SELECT DISTINCT
customer_id, market_date
FROM customer_purchases) as unique_dates
;
--Result for customer_id = 1 is 107

--dense_rank option to have the counter change on each new market date for each customer
SELECT market_date, customer_id,
dense_rank() OVER(ORDER BY customer_id, market_date ASC)as customer_visits_dense_rank
FROM customer_purchases;
--Result for customer_id =1 is 107


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT *

FROM (
	SELECT DISTINCT
	customer_id,
	market_date
	,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY market_date DESC) as customer_visits

	FROM customer_purchases
) x
WHERE x.customer_visits = 1;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT *,
COUNT(*) OVER(PARTITION BY product_id, customer_id) product_id_count

FROM customer_purchases
ORDER BY customer_id
;

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
DROP TABLE IF EXISTS new_product_table;

CREATE TEMP TABLE new_product_table AS
SELECT *,
TRIM(SUBSTR(product_name, CAST(INSTR(product_name, '-')+1 AS INT), CAST(INSTR(product_name, '-') AS INT)), ' ') AS Descriptions
 
FROM product;

UPDATE new_product_table
SET Descriptions = NULL
WHERE Descriptions= '';


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

DROP TABLE IF EXISTS new_new_product_table;

CREATE TEMP TABLE new_new_product_table AS
SELECT *,
TRIM(SUBSTR(product_name, CAST(INSTR(product_name, '-')+1 AS INT), CAST(INSTR(product_name, '-') AS INT)), ' ') AS Descriptions
 
FROM product
WHERE product_size REGEXP '^[0-9]';

UPDATE new_product_table
SET Descriptions = NULL
WHERE Descriptions= '';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

DROP TABLE IF EXISTS high_low_market_dates;

CREATE TEMP TABLE high_low_market_dates AS
SELECT market_date, count(customer_id)* quantity as sales
FROM customer_purchases
GROUP BY market_date;

DROP TABLE IF EXISTS rank_function_best_worst_day;

CREATE TEMP TABLE rank_function_best_worst_day AS
SELECT market_date, count(customer_id)* quantity as sales,
RANK() OVER(ORDER BY count(customer_id)* quantity ASC) rank_all
FROM customer_purchases
GROUP BY market_date;

SELECT *
FROM(
	SELECT DISTINCT
	market_date,sales,
	RANK () OVER (ORDER BY rank_all ASC) as best_and_worst_day

	FROM rank_function_best_worst_day
)x
WHERE x.best_and_worst_day = 1

UNION 

SELECT *
FROM (
	SELECT DISTINCT
	market_date,sales,
	RANK () OVER (ORDER BY rank_all DESC) best_day
	FROM rank_function_best_worst_day
) y
WHERE y.best_day = 1;

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- product_name and product_id is in product
-- vendor_name and vendor_id is in vendor
-- price, vendor_id and product_id is in vendor_inventory

SELECT DISTINCT vendor_id
FROM vendor_inventory;
-- vendors= 3

SELECT DISTINCT product_id
FROM vendor_inventory;
--products=8 (x)

SELECT DISTINCT customer_id
FROM customer_purchases;
--customers=26 (y)

DROP TABLE IF EXISTS vendors_get_rich;

CREATE TEMP TABLE vendors_get_rich AS
SELECT DISTINCT vi.vendor_id, vi.product_id,original_price, vendor_name, product_name, original_price*5 AS price_times_5
FROM vendor_inventory AS vi
INNER JOIN vendor AS v
	on vi.vendor_id = v.vendor_id
INNER JOIN product AS p
	on vi.product_id = p.product_id
GROUP BY vi.product_id;

DROP TABLE IF EXISTS simply_customer_id;

CREATE TEMP TABLE simply_customer_id AS
SELECT customer_id
FROM customer;

--For cross join, we should have x*y= 8*26=208

SELECT vendor_name, product_name, count(customer_id)* price_times_5 AS all_vendor_earnings
FROM  vendors_get_rich
CROSS JOIN simply_customer_id
GROUP BY vendor_name, product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;

CREATE TABLE product_units AS
SELECT product_id, product_name, product_size,product_category_id, product_qty_type , CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES(10, 'Eggs_2', '1 dozen', 6, 'unit', CURRENT_TIMESTAMP);

SELECT * FROM product_units;

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units
WHERE product_name = 'Eggs';

SELECT * FROM product_units;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;


-- get last quantity per product
--It should be the latest market_date for each product in vendor_inventory
DROP TABLE IF EXISTS temptable;

CREATE TEMP TABLE temptable AS
SELECT CAST(quantity as INT) as quantity,product_id
FROM (
SELECT market_date, vendor_id, product_id, quantity, 
	RANK() OVER(PARTITION BY product_id ORDER BY market_date DESC) as rank
	FROM vendor_inventory) x
WHERE x.rank = 1
ORDER BY product_id, market_date
;


UPDATE product_units
SET current_quantity = (
SELECT quantity FROM temptable
WHERE temptable.product_id= product_units.product_id
)
WHERE EXISTS(
SELECT 1
FROM temptable
WHERE temptable.product_id= product_units.product_id
)
;

SELECT product_id, product_name, 
product_size, product_category_id, 
product_qty_type, snapshot_timestamp, 
COALESCE(current_quantity, 0) as current_quantity
FROM product_units;

