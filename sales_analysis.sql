create database sales;
use sales;

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(30)
);

CREATE TABLE orders (
    order_id VARCHAR(30) PRIMARY KEY,
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    sales_person VARCHAR(100),

    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE products (
    product_id VARCHAR(30) PRIMARY KEY,
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255)
);

CREATE TABLE order_details (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(30),
    product_id VARCHAR(30),

    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id),

    FOREIGN KEY(product_id)
    REFERENCES products(product_id)
);



CREATE TABLE returns (
    order_id VARCHAR(30) PRIMARY KEY,
    returned VARCHAR(10),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);

# temporary table create kiye
CREATE TABLE retail_orders (
    row_id INT,
    order_id VARCHAR(30),
    order_date varchar(20),
    ship_date varchar(20),
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(30),
    sales_person VARCHAR(100),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    returned VARCHAR(10),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2)
);


SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM retail_orders;


INSERT INTO products (
    product_id,
    category,
    sub_category,
    product_name
)
SELECT
    product_id,
    MAX(category),
    MAX(sub_category),
    MAX(product_name)
FROM retail_orders
GROUP BY product_id;


select count(distinct product_id) as 'total_product' from products;

INSERT INTO products (
    product_id,
    category,
    sub_category,
    product_name
)
SELECT
    product_id,
    MAX(category),
    MAX(sub_category),
    MAX(product_name)
FROM retail_orders
GROUP BY product_id;

select * from products;



INSERT INTO orders (
    order_id,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    sales_person
)
SELECT
    order_id,
    STR_TO_DATE(MAX(order_date), '%d-%m-%Y'),
    STR_TO_DATE(MAX(ship_date), '%d-%m-%Y'),
    MAX(ship_mode),
    customer_id,
    MAX(sales_person)
FROM retail_orders
GROUP BY order_id, customer_id;

select * from orders;


INSERT INTO order_details (
    row_id,
    order_id,
    product_id,
    sales,
    quantity,
    discount,
    profit
)
SELECT
    row_id,
    order_id,
    product_id,
    sales,
    quantity,
    discount,
    profit
FROM retail_orders;

select * from order_details;

INSERT INTO returns (
    order_id,
    returned
)
SELECT DISTINCT
    order_id,
    returned
FROM retail_orders
WHERE returned IS NOT NULL;

select * from returns;

# analysis


select *from order_details;
# total sales
select sum(sales) as 'total_sales' from order_details;

# total profit

# Total Quantity Sold
select sum(quantity) as total_quantity_sold
from order_details;

# Find Total Orders
select count(*) as total_orders from orders;

# Find Region-wise Total Customers
select region, count(*) as total_customers from customers group by region
order by total_customers desc;

# Find Region-wise Total Sales

select *from customers;
select *from orders;
select *from order_details;


select c.region,sum(od.sales) as 'total_sales' from customers c
inner join sales.orders o on c.customer_id=o.customer_id
inner join sales.order_details od on o.order_id=od.order_id
group by c.region;

# Find Category-wise Total Profit
select *from products;
select *from order_details;

select p.category,sum(od.profit) as 'total_profit' from products p
inner join sales.order_details od on p.product_id=od.product_id group by p.category
order by total_profit desc;


# Top 10 Products by Total Sales
select p.product_name, sum(od.sales) as 'total_sales' from products p
inner join sales.order_details od on p.product_id=od.product_id group by product_name
order by total_sales desc limit 10;

# Top 5 Customers by Total Sales
select c.customer_name,sum(od.sales) as 'total_sales'
from customers c inner join sales.orders o on c.customer_id=o.customer_id
inner join sales.order_details od on o.order_id=od.order_id
group by c.customer_name order by total_sales desc limit 5;



# Monthly Sales Trend

select *from orders;
select *from order_details;

select year(o.order_date) as year, monthname( o.order_date) as 'month',sum(od.sales) as 'monthly_sales'  from orders o
 inner join order_details od on o.order_id=od.order_id
group by year(o.order_date), monthname( o.order_date)
order by year(o.order_date), monthname( o.order_date);



# Top 5 Loss Making Products
select p.product_name,sum(od.profit) as total_profit
from products p inner join order_details od on p.product_id=od.product_id
group by p.product_name having sum(od.profit)< 0
order by total_profit asc limit 5;


#Find the Top 3 Customers in each Region based on Total Sales.

with customer_sales as (select c.region, c.customer_name, sum(od.sales) as total_sale
                        from customers c
                                 inner join orders o on c.customer_id = o.customer_id
                                 inner join order_details od on o.order_id = od.order_id
                        group by c.region, c.customer_name
                        order by total_sale desc
),
ranked_customers as (
    select region,customer_name,total_sale,
           dense_rank() over (partition by region order by total_sale desc) as customer_rank
    from customer_sales
)
select *
from ranked_customers
where customer_rank <=3
order by region,customer_rank;


# Find the Top 5 Products in each Category based on Total Sales.

with product_sales as (select p.product_name,p.category, sum(od.sales) as total_sales from products p
inner join sales.order_details od on p.product_id=od.product_id
group by p.product_name,p.category order by total_sales desc),

ranked_product as (
    select product_name,category,total_sales,
           dense_rank() over (partition by category order by total_sales desc ) as product_rank
    from product_sales
)
select *
from ranked_product
where product_rank <=5
order by category,product_rank;

# Find the Top 3 States in each Region based on Total Sales.

select *from customers;

with top_state as (select c.state,c.region, sum(od.sales) as total_sales
from customers c
inner join sales.orders o on c.customer_id=o.customer_id
inner join sales.order_details od on o.order_id=od.order_id
group by c.state,c.region),

rank_of_state as (
    select state,region, total_sales,
           dense_rank() over (partition by region order by total_sales desc ) as ranked_state
    from top_state
)
select *
from rank_of_state
where ranked_state <=3
order by region,ranked_state;

# Find Month-over-Month (MoM) Sales Growth
select *from orders;
select *from order_details;


with monthly_sales as (select year(o.order_date) as year,month(order_date)as month_no ,monthname(o.order_date) as month, sum(od.sales) as total_sales
                       from orders o
                                inner join order_details od on o.order_id = od.order_id
                       group by year(o.order_date), month(o.order_date), monthname(o.order_date)
                       ),
    sales_groth as(
        select year,month_no,month, total_sales,
               lag(total_sales)  over (order by year,month_no) as previous_month_sales
        from monthly_sales)
select * from sales_groth;

# Find Profit Margin % by Category

select p.category,sum(od.sales) as total_sales, sum(od.profit) as total_profit,
       ROUND((SUM(od.profit) / SUM(od.sales)) * 100, 2) AS profit_margin
from products p
inner join sales.order_details od on p.product_id  =od.product_id
group by category;

# Average Order Value (AOV)
select *from order_details;
select *from orders;

select sum(sales) as total_sales, count(distinct (order_id)) as total_orders,
       sum(sales) /count(distinct (order_id)) as total_order_vale
from order_details;

# Region-wise Total Sales aur Total Profit
select c.region, sum(od.sales) as total_sales,sum(od.profit) as total_profit
from customers c
inner join orders o on c.customer_id=o.customer_id
inner join order_details od on o.order_id=od.order_id
group by c.region;

# Find Segment-wise Total Sales and Total Profit.

select c.segment,sum(od.sales) as total_sales, sum(od.profit) as total_profit
from customers c
inner join orders o on c.customer_id=o.customer_id
inner join order_details od on o.order_id=od.order_id
group by c.segment;

# Find Sub-Category-wise Total Sales and Total Profit.
select p.sub_category, sum(od.sales) as total_sales, sum(od.profit)
from products p
inner join  order_details od on p.product_id=od.product_id
group by p.sub_category;

# Find Top 10 Cities based on Total Sales.

select c.city, sum(od.sales) as total_sales from customers c
inner join orders o on c.customer_id=o.customer_id
inner join order_details od on o.order_id=od.order_id
group by c.city
order by total_sales desc limit 10;

# Find Total Sales by Ship Mode.
select o.ship_mode, sum(od.sales) as total_sales from orders o
inner join order_details od on o.order_id=od.order_id
group by o.ship_mode;

# Find the Top 10 Products with the highest total profit.
select p.product_name , sum(od.profit) as total_profit from products p
inner join order_details od on p.product_id=od.product_id
group by p.product_name
order by total_profit desc
limit 10;

# Find the Top 10 Products with the highest total discount.
select p.product_name, sum(od.discount) as total_discount from products p
inner join order_details od on p.product_id=od.product_id
group by p.product_name
order by total_discount desc
limit 10;

# Find the relationship between Discount and Profit.

select discount, sum(sales) as total_sales,sum(profit)
as total_profit from order_details
group by    discount;

# Find Discount-wise Profit Margin.
select discount, sum(sales) as total_sales,sum(profit)
as total_profit,
    round((sum(profit)/sum(sales))*100,2) as Profit_margin
from order_details
group by    discount;


# Har category total sales me kitna % contribute karti hai?

select*from products;

with categry_sales as
    (select p.category,sum(od.sales) as total_sales from products p
inner join order_details od on p.product_id=od.product_id
group by p.category)

select  category,total_sales,
        round(
        (total_sales/(select sum(sales) from order_details))*100 ,2
        ) as Sales_Contribution_percnt
from categry_sales
order by Sales_Contribution_percnt desc ;

# Har month ki sales ke saath ab tak ki cumulative (running) sales dikhao.

WITH monthly_sales AS (
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month_no,
        MONTHNAME(o.order_date) AS month,
        SUM(od.sales) AS total_sales
    FROM orders o
    INNER JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date),
        MONTHNAME(o.order_date)
)
SELECT
    year,
    month,
    total_sales,
    SUM(total_sales) OVER (
        ORDER BY year, month_no
    ) AS running_total_sales
FROM monthly_sales
ORDER BY year, month_no;

# Month-over-Month Growth %
# → Current month vs previous month
WITH monthly_sales AS (
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month_no,
        MONTHNAME(o.order_date) AS month,
        SUM(od.sales) AS total_sales
    FROM orders o
    INNER JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date),
        MONTHNAME(o.order_date)
),

sales_with_previous AS (
    SELECT
        year,
        month_no,
        month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY year, month_no
        ) AS previous_month_sales
    FROM monthly_sales
)

SELECT
    year,
    month,
    total_sales,
    previous_month_sales,
    ROUND(
        ((total_sales - previous_month_sales)
        / previous_month_sales) * 100,
        2
    ) AS mom_growth_percent
FROM sales_with_previous
ORDER BY year, month_no;


# Year-over-Year (YoY) Growth %
#
# Matlab:
#
# Is year ki sales pichhle year ke comparison me kitni % increase/decrease hui?
WITH yearly_sales AS (
    SELECT
        YEAR(o.order_date) AS year,
        SUM(od.sales) AS total_sales
    FROM orders o
    INNER JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY YEAR(o.order_date)
),

yearly_with_previous AS (
    SELECT
        year,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY year
        ) AS previous_year_sales
    FROM yearly_sales
)

SELECT
    year,
    total_sales,
    previous_year_sales,
    ROUND(
        ((total_sales - previous_year_sales)
        / previous_year_sales) * 100,
        2
    ) AS yoy_growth_percent
FROM yearly_with_previous
ORDER BY year;


