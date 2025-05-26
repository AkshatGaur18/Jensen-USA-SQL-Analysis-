# Jenson USA Bike Stores Database Analysis

This repository contains SQL scripts and analysis related to the Jenson USA Bike Stores sample database. The project focuses on understanding sales performance, customer behavior, and product insights through various SQL queries.

## Table of Contents

* [Project Overview](#project-overview)

* [Database Schema](#database-schema)

* [SQL Scripts](#sql-scripts)

  * [Database Creation and Data Loading](#database-creation-and-data-loading)

  * [Analytical Queries](#analytical-queries)

* [Key Insights and Analysis](#key-insights-and-analysis)

* [How to Use](#how-to-use)

* [Contributing](#contributing)


## Project Overview

This project aims to perform a comprehensive data analysis on a sample Bike Stores database. The primary goals include:

* Setting up the database schema and loading sample data.

* Executing various SQL queries to extract meaningful insights.

* Analyzing sales trends, product performance, and customer purchasing patterns.

* Identifying top-selling products, high-value customers, and efficient stores.

The analysis is structured to provide a clear understanding of the business operations within the bike retail context, enabling data-driven decision-making.

## Database Schema

The database is designed to manage information about stores, products, customers, orders, and stock. It consists of the following key tables:

* **`stores`**: Information about each bike store (ID, name, contact details, address).

* **`categories`**: Different categories of bicycles (e.g., Mountain Bikes, Electric Bikes).

* **`brands`**: Brands of bicycles available.

* **`products`**: Details of each product, including name, brand, category, model year, and list price.

* **`customers`**: Customer details (name, phone, email, address).

* **`staffs`**: Information about employees.

* **`orders`**: Records of customer orders, linking to customers, stores, and staff.

* **`order_items`**: Details of each item within an order, including product, quantity, list price, and discount.

* **`stocks`**: Current stock levels for each product at each store.

The schema is defined in `BikeStores Sample Database - create objects.sql`.

## SQL Scripts

This repository includes two main SQL script files:

### Database Creation and Data Loading

* **`BikeStores Sample Database - create objects.sql`**: This script contains the SQL commands to create the `Jenkins` database and all the necessary tables (stores, categories, brands, products, customers, staffs, orders, order_items, stocks) with their respective columns, primary keys, and foreign key relationships.

* **`BikeStores Sample Database - load data.sql`**: This script populates the tables created by the `create objects` script with sample data for brands, categories, products, customers, staffs, stores, and orders. This data is essential for running the analytical queries.

### Analytical Queries

The `Jenson Milestone.sql` file contains a series of analytical SQL queries designed to extract valuable business insights. Below are some examples of the queries included:

 1. **Total Products Sold by Each Store**:
    This query calculates the total quantity of products sold by each store, providing an overview of store performance.

    ```sql
    SELECT
        s.store_name, SUM(oi.quantity) AS products_sold
    FROM
        stores s
    JOIN orders o ON s.store_id = o.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY s.store_name;
    ```

 2. **Cumulative Sum of Quantities Sold for Each Product Over Time**:
    This query demonstrates the use of window functions to calculate a running total of quantities sold for each product, ordered by date. This helps in understanding product sales trends over time.

    ```sql
    SELECT
        order_date,
        p.product_name ,
        oi.quantity,
        SUM(oi.quantity) OVER(PARTITION BY p.product_id ORDER BY order_date) AS cumulative_sum
    FROM
        orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id;
    ```

 3. **Product with the Highest Total Sales for Each Category**:
    Identifies the top-selling product (by total sales value) within each product category using Common Table Expressions (CTEs) and `DENSE_RANK()`.

    ```sql
    WITH cte AS (
        SELECT
            oi.product_id,
            product_name,
            category_name,
            SUM(quantity * oi.list_price) AS sales
        FROM
            order_items oi
        JOIN products p ON p.product_id = oi.product_id
        JOIN categories c ON c.category_id = p.category_id
        GROUP BY
            product_id,
            category_name
        ORDER BY
            product_id
    ),
    cte_2 AS (
        SELECT
            *,
            DENSE_RANK() OVER(PARTITION BY category_name ORDER BY sales DESC) AS rnk
        FROM
            cte
    )
    SELECT
        category_name,
        product_name,
        sales
    FROM
        cte_2
    WHERE
        rnk = 1;
    ```

 4. **Customer Who Spent the Most Money on Orders**:
    Finds the customer with the highest total spending, considering quantity, list price, and discounts.

    ```sql
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM((oi.quantity * oi.list_price)) - ROUND(SUM((oi.quantity * oi.list_price) * (discount / 100)),2) AS spents
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN
        order_items oi ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id, c.first_name, c.last_name
    ORDER BY
        spents DESC
    LIMIT 1;
    ```

 5. **Highest-Priced Product for Each Category Name**:
    Identifies the product with the highest `list_price` within each category.

    ```sql
    WITH cte AS (
        SELECT
            p.product_id,
            c.category_name AS category,
            p.product_name,
            p.list_price AS price,
            DENSE_RANK() OVER (
                PARTITION BY c.category_name
                ORDER BY p.list_price DESC
            ) AS rnk
        FROM
            products p
        JOIN
            categories c ON p.category_id = c.category_id
    )
    SELECT
        category,
        product_name,
        price
    FROM
        cte
    WHERE
        rnk = 1;
    ```

 6. **Total Number of Orders Placed by Each Customer Per Store**:
    Aggregates order counts for each customer, broken down by the store where the order was placed.

    ```sql
    SELECT
        s.store_name,
        c.first_name,
        c.last_name,
        COUNT(o.order_id) AS total_orders
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN
        stores s ON o.store_id = s.store_id
    GROUP BY
        s.store_name,
        c.first_name,
        c.last_name
    ORDER BY
        s.store_name,
        total_orders DESC;
    ```

 7. **Median List Price of Products**:
    Calculates the median `list_price` across all products, handling both odd and even numbers of records.

    ```sql
    WITH cte AS (
        SELECT
            list_price,
            ROW_NUMBER() OVER (ORDER BY list_price) AS row_num,
            COUNT(list_price) OVER () AS n
        FROM
            products
    )
    SELECT
        CASE
            WHEN n % 2 != 0 THEN (SELECT list_price FROM cte WHERE row_num = (n + 1) / 2)
            ELSE (SELECT AVG(list_price) FROM cte WHERE row_num IN (n / 2, (n / 2) + 1))
        END AS median_list_price
    FROM
        cte
    LIMIT 1;
    ```

 8. **Top 3 Most Sold Products in Terms of Quantity**:
    Identifies the products with the highest total quantities sold.

    ```sql
    WITH cte AS (
        SELECT
            oi.product_id AS product_id,
            p.product_name AS product_name,
            SUM(oi.quantity) AS total_quantity
        FROM
            products p
        JOIN
            order_items oi
            ON p.product_id = oi.product_id
        GROUP BY
            product_id,
            product_name
    ),
    cte_2 AS (
        SELECT
            *,
            DENSE_RANK() OVER (
                ORDER BY total_quantity DESC) AS rnk
        FROM
            cte
    )
    SELECT
        product_id,
        product_name,
        total_quantity
    FROM
        cte_2
    WHERE
        rnk <= 3;
    ```

 9. **List all products that have never been ordered**:
    This query identifies products that have no associated order items, indicating they have never been sold. It uses both `NOT IN` and `NOT EXISTS` for demonstration.

    ```sql
    SELECT * FROM products WHERE product_id NOT IN (
        SELECT DISTINCT(product_id) FROM order_items
    );

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
    ```

10. **Names of Staff Members Who Have Made More Sales Than the Average**:
    This query identifies staff members whose total sales (quantity * list_price) exceed the average sales across all staff members.

    ```sql
    WITH staff_sales AS (
        SELECT
            s.staff_id,
            s.first_name,
            s.last_name,
            COALESCE(SUM(oi.quantity * oi.list_price), 0) AS total_sales
        FROM
            staffs s
        LEFT JOIN orders o ON s.staff_id = o.staff_id
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY
            s.staff_id, s.first_name, s.last_name
    ),
    avg_sales AS (
        SELECT
            AVG(total_sales) AS avg_staff_sales
        FROM
            staff_sales
    )
    SELECT
        ss.staff_id,
        ss.first_name,
        ss.last_name,
        ss.total_sales
    FROM
        staff_sales ss
    JOIN avg_sales ON ss.total_sales > avg_sales.avg_staff_sales;
    ```

11. **Customers who have ordered all types of products (i.e., from every category)**:
    This query identifies customers who have placed orders for at least one product from every available category.

    ```sql
    SELECT
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN
        order_items oi ON o.order_id = oi.order_id
    JOIN
        products p ON oi.product_id = p.product_id
    GROUP BY
        c.customer_id, c.first_name, c.last_name
    HAVING
        COUNT(DISTINCT p.category_id) = (SELECT COUNT(DISTINCT category_id) FROM categories);
    ```

## Key Insights and Analysis

The SQL queries provide several valuable insights into the Jenson USA Bike Stores operations:

* **Sales Performance by Store**: The analysis of total products sold by each store helps identify top-performing locations and areas that might need improvement or further investment.

* **Product Popularity and Trends**: By calculating cumulative sums and identifying top-selling products, we can understand which products are most popular and how their sales evolve over time. This can inform inventory management and marketing strategies.

* **Customer Value**: Identifying the customer who spent the most money allows for targeted marketing efforts, loyalty programs, or personalized recommendations for high-value customers.

* **Product Pricing Strategy**: Analyzing the highest-priced products per category gives an overview of the premium offerings and pricing tiers within different bicycle types. The median list price provides a central tendency for product pricing.

* **Customer Engagement**: Tracking orders per customer per store can reveal customer loyalty to specific locations or highlight opportunities for cross-store promotions.

* **Inventory Optimization**: The query for products never ordered is crucial for identifying dead stock, optimizing inventory, and preventing future losses on unpopular items.

* **Staff Performance**: Comparing individual staff sales against the average helps identify high-performing staff members who could be rewarded or serve as mentors, and those who might need additional training.

* **Customer Segmentation**: Identifying customers who have purchased from every category indicates highly engaged or diverse customers, which could be a valuable segment for broad product promotions.

These insights can be further visualized and integrated into business intelligence dashboards to support strategic planning and operational adjustments.

## How to Use

To use this project:

1. **Set up MySQL**: Ensure you have a MySQL server running.

2. **Create Database and Tables**: Execute the `BikeStores Sample Database - create objects.sql` script to create the `Jenkins` database and its tables.

   ```bash
   mysql -u your_username -p < "BikeStores Sample Database - create objects.sql"
   
3. **Load Data**: Execute the BikeStores Sample Database - load `data.sql` script to populate the database with sample data.
   ```bash
   mysql -u your_username -p Jenkins < "BikeStores Sample Database - load data.sql"
   
4. **Run Analytical Queries**: Open `Jenson Milestone.sql` in your MySQL client (e.g., MySQL Workbench, DBeaver, or command line) and execute the queries individually or as a batch to get the analytical results.


## Contributing
Feel free to fork this repository, suggest improvements, or add more analytical queries. Pull requests are welcome!
