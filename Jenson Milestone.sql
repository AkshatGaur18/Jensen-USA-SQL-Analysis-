use jerkins;

#1 Find the total number of products sold by each store along with the store name.

SELECT 
    s.store_name, SUM(oi.quantity) AS products_sold
FROM
    stores s
JOIN orders o ON s.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY s.store_name;


#2. Calculate the cumulative sum of quantities sold for each product over time.

select order_date,
p.product_name ,
oi.quantity,
sum(oi.quantity) over(partition by p.product_id order by order_date) cumalative_sum
from orders o join order_items oi on
o.order_id = oi.order_id join products p
on oi.product_id = p.product_id;

#3. Find the product with the highest total sales (quantity * price) for each category.
with cte as (
select oi.product_id,product_name,category_name, sum(quantity*oi.list_price) as sales from order_items oi
join products p on p.product_id = oi.product_id
join categories c on c.category_id = p.category_id 
group by product_id,category_name
order by product_id)
,cte_2 as(
select *, dense_rank() over(partition by category_name order by sales desc) rnk from cte)
select category_name , product_name , sales from cte_2 
where rnk = 1;

#4. Find the customer who spent the most money on orders.
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) customer_name,
    SUM((oi.quantity * oi.list_price)) - ROUND(SUM((oi.quantity * oi.list_price) * (discount / 100)),
            2) AS spents
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id , c.first_name , c.last_name
ORDER BY spents DESC
LIMIT 1;

#5. Find the highest-priced product for each category name.
with cte as (
select p.product_id,
c.category_name category, 
p.product_name product_name ,
(p.list_price) price,
dense_rank() over (partition by c.category_name order by p.list_price desc) rnk
from products p join categories c on
p.category_id = c.category_id) 
select category, product_name ,price from cte where rnk =1 ;


#6. Find the total number of orders placed by each customer per store.
SELECT 
    s.store_name,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) total_orders
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    stores s ON o.store_id = s.store_id
GROUP BY s.store_id ,c.customer_id, c.first_name , c.last_name;

#7. Find the names of staff members who have not made any sales.

SELECT 
    first_name, last_name
FROM
    staffs
WHERE
    staff_id NOT IN (SELECT DISTINCT
            (staff_id)
        FROM
            orders);

#8. Find the top 3 most sold products in terms of quantity.
with cte as (
select (oi.product_id) product_id,p.product_name product_name ,sum(oi.quantity)  total_quantity 
from products p join order_items oi on p.product_id = oi.product_id
group by product_id,product_name),
cte_2 as (
select *,dense_rank()over (order by total_quantity desc) rnk from cte)
select product_id,product_name,total_quantity from cte_2 where rnk<=3;


#9. Find the median value of the price list. 
with cte as(
select list_price,row_number() over() as row_num ,count(list_price) over() as n from products order by list_price)
select
case
when n%2!=0 then (select list_price from cte where row_num in ((n+1)/2))
else  (select avg(list_price) from cte where row_num in ((n/2),(n+1)/2))
end as median
from cte
limit 1;

#10.List all products that have never been ordered.(use Exists)
select * from products where product_id not in(
select distinct(product_id) from order_items);

SELECT 
    *
FROM
    products p
WHERE
    NOT EXISTS( SELECT 
            product_id
        FROM
            order_items oi
        WHERE
            oi.product_id = p.product_id);

#11. List the names of staff members who have made more sales than the average number of sales by all staff members
with cte As(
select s.staff_id,s.first_name,s.last_name, coalesce(sum(oi.quantity*oi.list_price),0) total_sales from staffs s 
left join orders o on s.staff_id = o.staff_id
left join order_items oi on o.order_id = oi.order_id
group by s.staff_id,s.first_name,s.last_name)
, cte2 as
(select avg(total_sales) as avg_sales from cte)

select cte.staff_id,cte.first_name,cte.last_name from cte 
join cte2 on cte.total_sales > cte2.avg_sales;


#12 Identify the customers who have ordered all types of products (i.e., from every category)

SELECT 
    (CONCAT(c.first_name, ' ', c.last_name)) customer_name
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
GROUP BY customer_name
HAVING COUNT(DISTINCT (p.category_id)) = (SELECT 
        COUNT(DISTINCT (category_id))
    FROM
        categories);
