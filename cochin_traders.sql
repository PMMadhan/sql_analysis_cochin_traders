

--QS-1: Fetch the full name and hiring date of all Employees who work as
--Sales Representatives.
SELECT CONCAT(firstname," ",lastname) AS full_name, hiredate, title FROM cochin_traders.employees
WHERE title = 'Sales Representative'

--QS-2: Which of the products in our inventory need to be reordered?
SELECT * FROM cochin_traders.products
where unitsinstock < reorderlevel
ORDER BY 1

--QS-3: Find and display the details of customers who have placed more than 5 orders.
WITH a AS
(SELECT customerid, COUNT(customerid) AS No_of_orders FROM cochin_traders.orders
GROUP BY customerid
HAVING COUNT(customerid)>5 )
SELECT a.customerid, a.No_of_orders, c.companyname, c.contactname, c.contacttitle, c.city, c.region, c.country
 FROM a JOIN cochin_traders.customers AS c ON a.customerid = c.customerid
 ORDER BY a.No_of_orders
 ------------
 --optimized query
WITH a AS
(SELECT customerid FROM cochin_traders.orders
GROUP BY customerid
HAVING COUNT(customerid)>5)
SELECT * FROM cochin_traders.customers
WHERE customerid IN (SELECT * FROM a)

 --QS-4: An employee of ours (Margaret Peacock, EmployeeID 4) has the record of
--completing most orders. However, there are some customers who have never placed an order with her. Show such customers.
---soln using CTE and JOINS
WITH emp4order AS
(SELECT * FROM cochin_traders.orders
WHERE employeeid=4)
SELECT DISTINCT c.customerid, c.companyname, c.contactname, c.contacttitle
FROM cochin_traders.customers AS c LEFT JOIN emp4order AS e ON c.customerid = e.customerid
WHERE e.customerid IS NULL
---SOlution using Subquery
SELECT DISTINCT customerid, companyname, contactname, contacttitle
FROM cochin_traders.customers
WHERE customerid NOT IN (
SELECT customerid FROM cochin_traders.orders 
WHERE employeeid =4)

--QS-5: Retrieve the top 5 best-selling products on the basis of the quantity ordered.
-- Solution using orderby & LIMIT
WITH topquantity AS
(
SELECT productid, SUM(quantity) AS total_quantity 
FROM cochin_traders.orders_details
GROUP BY productid
ORDER BY SUM(quantity) DESC
LIMIT 5
)
SELECT * FROM topquantity AS t JOIN cochin_traders.products AS p ON t.productid=p.productid;
---Solution using DENSE RANK
WITH topquantity AS
(
SELECT productid, SUM(quantity) AS total_quantity 
FROM cochin_traders.orders_details
GROUP BY productid
)
,rnk AS
(SELECT p.*, DENSE_RANK() OVER(ORDER BY t.total_quantity DESC) AS quantityrnk
FROM topquantity AS t JOIN cochin_traders.products AS p ON t.productid=p.productid)
SELECT * FROM rnk
WHERE quantityrnk<=5;
 
--QS-6: Analyze the monthly order count for the year 1997.
 SELECT MONTH(orderdate) AS month, COUNT(*) AS Monthly_Order_Count FROM cochin_traders.orders
 WHERE YEAR(orderdate)=1997
 GROUP BY month
 
 --QS-7: Calculate the difference in sales revenue for each month compared to the previous month.
with revenue AS
(SELECT *, ROUND(unitprice*quantity) AS rev
FROM cochin_traders.orders_details),
monthsplit AS
(SELECT r.*, YEAR(o.orderdate) AS orderyear, MONTH(o.orderdate) AS ordermonth
FROM revenue AS r JOIN cochin_traders.orders AS o ON r.orderid=o.orderid
ORDER BY orderyear, ordermonth)
SELECT orderyear,ordermonth,  SUM(rev) AS total_monthly_order,
LAG(SUM(rev),1,0) OVER() AS prev_month_revenue,
SUM(rev)-LAG(SUM(rev),1,0) OVER() AS diff_revenue_prevmonth
FROM monthsplit
GROUP BY orderyear,ordermonth

--QS-8: Calculate the percentage of total sales revenue for each product.
with revenue AS
(SELECT *, ROUND(unitprice*quantity) AS rev
FROM cochin_traders.orders_details),
total_revenue AS
(SELECT SUM(rev) AS total_revenue
FROM revenue),
product_revenue AS
(SELECT p.productid, p.productname, SUM(r.rev) AS product_revenue
FROM revenue AS r JOIN cochin_traders.products AS p ON r.productid = p.productid
GROUP BY p.productid, p.productname)
SELECT pr.productid, pr.productname, pr.product_revenue, tr.total_revenue, 
ROUND((pr.product_revenue/tr.total_revenue)*100,2) AS percentage_of_total_revenue,
ROUND(SUM(ROUND((pr.product_revenue/tr.total_revenue)*100,2)) OVER(ORDER BY pr.productid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS cum_perct
FROM product_revenue AS pr JOIN total_revenue AS tr 

