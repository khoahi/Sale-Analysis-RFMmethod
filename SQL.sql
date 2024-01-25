select * from dbo.customers
SELECT COUNT (distinct customer_ID) AS count_result
FROM dbo.customers

select * from dbo.order_reviews
select * from dbo.order_items
select * from dbo.geolocation
select * from dbo.order_payments
select * from dbo.orders
select * from dbo.products
select * from dbo.sellers
select * from dbo.product_category_name_translation

#Cau 1 2 3

WITH CTE1 AS (
    SELECT c.customer_unique_id, o.*, oi.price + oi.freight_value AS total_value
    FROM orders o
    LEFT JOIN customers c
    ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
),
RFM_value AS (
    SELECT customer_unique_id,
        MIN(datediff(day, order_purchase_timestamp,'2019-01-01')) AS order_recency,
        COUNT(DISTINCT order_id) AS order_frequency,
        SUM(total_value) order_monetary
    FROM CTE1
    GROUP BY customer_unique_id
),
RFM_percent AS (
    SELECT *, 
        PERCENT_RANK() OVER (ORDER BY order_recency DESC) AS percent_recency,
        PERCENT_RANK() OVER (ORDER BY order_frequency) AS percent_frequency,
        PERCENT_RANK() OVER (ORDER BY order_monetary) AS percent_monetary
    FROM RFM_value
),
RFM_score AS (
    SELECT customer_unique_id,
        CASE WHEN percent_recency <= 0.25 THEN 0
        WHEN percent_recency  <= 0.5 THEN 1
        WHEN percent_recency <= 0.75 THEN 2
        ELSE 3
        END AS R_score,
        CASE WHEN percent_frequency <= 0.25 THEN 0
        WHEN percent_frequency  <= 0.5 THEN 1
        WHEN percent_frequency <= 0.75 THEN 2
        ELSE 3
        END AS F_score,
        CASE WHEN percent_monetary <= 0.25 THEN 0
        WHEN percent_monetary  <= 0.5 THEN 1
        WHEN percent_monetary <= 0.75 THEN 2
        ELSE 3
        END AS M_score
    FROM RFM_percent
),
tệp_khách_hàng AS (
    SELECT customer_unique_id, 
        CASE WHEN CONCAT(R_score, F_score, M_score) in (222,223,232,233,322,323,332,333) THEN 'best'
        WHEN CONCAT(R_score, F_score, M_score) in (220,221,230,231,320,321,330,331) THEN 'loyal'
        WHEN CONCAT(R_score, F_score, M_score) in (210,211,212,213,310,311,312,313) THEN 'potential'
        WHEN CONCAT(R_score, F_score, M_score) in (200,201,202,203,300,301,302,303) THEN 'new'
        WHEN CONCAT(R_score, F_score, M_score) in (100,101,102,103,110,111,112,113,120,121,122,123,130,131,132,133) THEN 'có kha nang churn'
        ELSE 'churned'
        END tệp_khách_hàng
    FROM RFM_score
),
group_customer_type AS ( 
    SELECT tệp_khách_hàng,
        COUNT(customer_unique_id) AS 'So luong'
    FROM tệp_khách_hàng
    GROUP BY tệp_khách_hàng
)
SELECT * 
FROM group_customer_type

#Cau 4a
SELECT SUM(price * order_item_id) AS total_revenue
FROM dbo.order_items;

#theo tháng
SELECT 
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS month,
    SUM(payment_value) AS total_payment
FROM 
    orders
    JOIN order_payments ON orders.order_id = order_payments.order_id
GROUP BY 
    FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY 
    month;

#Cau 4b
select distinct order_status
from dbo.orders

select count (order_id) as 'Tong so don hang'
from dbo.orders
where order_status != 'unavailable' AND order_status !=  'canceled'

#theo tháng
SELECT
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS month,
    COUNT(order_id) AS total_orders
FROM
    dbo.orders
WHERE
    order_status NOT IN ('unavailable', 'canceled')
GROUP BY
    FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY
    month;


#Cau 4c
WITH CategoryStats AS (
    SELECT
        pcnt.product_category_name_english,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(price + freight_value) AS total_sales
    FROM
        order_items oi
    LEFT JOIN
        products p ON oi.product_id = p.product_id
    LEFT JOIN
        product_category_name_translation pcnt ON p.product_category_name = pcnt.product_category_name
    GROUP BY
        pcnt.product_category_name_english
)

SELECT
    product_category_name_english,
    total_orders,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS category_rank
FROM
    CategoryStats
ORDER BY
    category_rank;


#Cau 4d

- Giá trị AOV tổng: 

WITH CTE AS (
SELECT pcnt.product_category_name_english,
    COUNT(DISTINCT oi.order_id) AS total_order,
    SUM(price) + SUM(freight_value) AS total_value
FROM order_items oi
LEFT JOIN products p
ON oi.product_id = p.product_id 
LEFT JOIN product_category_name_translation pcnt
ON p.product_category_name = pcnt.product_category_name
GROUP BY pcnt.product_category_name_english
)
SELECT SUM(total_value) / SUM(total_order) AS 'Gia Tri AOV Tren Olist'
FROM CTE

- Theo product category:
WITH CTE AS (
    SELECT
        pcnt.product_category_name_english,
        COUNT(DISTINCT oi.order_id) AS total_order,
        SUM(price + freight_value) AS total_value
    FROM
        order_items oi
    LEFT JOIN
        products p ON oi.product_id = p.product_id
    LEFT JOIN
        product_category_name_translation pcnt ON p.product_category_name = pcnt.product_category_name
    GROUP BY
        pcnt.product_category_name_english
)

SELECT
    product_category_name_english as 'Product Category',
    total_value / total_order AS 'AOV theo Product Category'
FROM
    CTE
ORDER BY
    'AOV theo Product Category' DESC

- Theo Payment Method
WITH CTE AS (
    SELECT
        op.payment_type,
        COUNT(DISTINCT oi.order_id) AS total_order,
        SUM(price + freight_value) AS total_value
    FROM
        order_items oi
    LEFT JOIN
        products p ON oi.product_id = p.product_id
    LEFT JOIN
        order_payments op ON oi.order_id = op.order_id
    GROUP BY
        op.payment_type
)

SELECT
    payment_type as 'Payment',
    total_value / total_order AS 'AOV theo Payment'
FROM
    CTE
ORDER BY
    'AOV theo Payment' DESC
