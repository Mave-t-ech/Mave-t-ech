select * from dannys_diner.menu;
select * from dannys_diner.sales;
select * from dannys_diner.members;

--question 1 the total amount spent by each customer.
with cte_sales as (select customer_id, sales.product_id, sum(price) AS Amount_spent, menu.product_name
from dannys_diner.sales AS sales
left join dannys_diner.menu AS Menu
on sales.product_id = menu.product_id
group by customer_id, sales.product_id, menu.product_name
order by customer_id)
select customer_id, sum (amount_spent) as total_spent
from cte_sales
group by customer_id;

--Question 1 method 2. lmaooo
select customer_id, sum (amount_spent) as total_spent
from (select customer_id, sales.product_id, sum(price) AS Amount_spent, menu.product_name
from dannys_diner.sales AS sales
left join dannys_diner.menu AS Menu
on sales.product_id = menu.product_id
group by customer_id, sales.product_id, menu.product_name
order by customer_id ) as New_table
group by customer_id;

-- Q2 number of days each customer visited
SELECT customer_id, count(distinct order_date) as no_of_days
from dannys_diner.sales
group by customer_id
order by customer_id;

--Q3 what was the first item on the menu purcahsed by the customer?
SELECT customer_id, product_name, product_id, order_date,
Rank () Over (partition by customer_id order by order_date) as rnk,
Row_number () Over (partition by customer_id order by order_date) as rw
from (select customer_id, order_date, sales.product_id, sum(price) AS Amount_spent, menu.product_name
from dannys_diner.sales AS sales
left join dannys_diner.menu AS Menu
on sales.product_id = menu.product_id
group by customer_id, sales.product_id, menu.product_name, order_date
order by customer_id) as new_table;

select *
from (SELECT customer_id, product_name, product_id, order_date,
Rank () Over (partition by customer_id order by order_date) as rnk,
Row_number () Over (partition by customer_id order by order_date) as rw
from (select customer_id, order_date, sales.product_id, sum(price) AS Amount_spent, menu.product_name
from dannys_diner.sales AS sales
left join dannys_diner.menu AS Menu
on sales.product_id = menu.product_id
group by customer_id, sales.product_id, menu.product_name, order_date
order by customer_id) as new_table) as old_table
where rw = 1;

-- Q4 
--what is the most purchased item on the menu and how many times was it purchased?
select menu.product_name, count(order_date) as most_purchased
from dannys_diner.sales AS sales
left join dannys_diner.menu AS Menu
on sales.product_id = menu.product_id
group by menu.product_name
order by count(order_date) desc
limit 1;

/* Q5 which item is the most popular for each customer? */
select *
from (select customer_id, count (order_date), product_name,
Row_number () Over (partition by customer_id order by count (order_date)) as rnk
from dannys_diner.sales AS s
left join dannys_diner.menu AS M
on s.product_id = m.product_id
group by product_name, s.customer_id
order by product_name desc) as new_new
where rnk = 1;

--Q6 which item was purchased first after they became a member?
select *
from dannys_diner.members;

with cte as (select customer_id, order_date, m.product_id, join_date, product_name, price,
Row_number () Over (partition by customer_id order by order_date) as rnk
from (select s.customer_id, order_date, product_id, join_date
from dannys_diner.sales AS s
left join dannys_diner.members AS mb
on s.customer_id = mb.customer_id) as mem_table
left join dannys_diner.menu AS m
ON mem_table.product_id = m.product_id
where order_date >= join_date)

select *
from cte
where rnk = 1;

--Q7 which item was purchased just before they became a member
with cte as (select customer_id, order_date, m.product_id, join_date, product_name, price,
Row_number () Over (partition by customer_id order by order_date desc) as rwn,
Rank () Over (partition by customer_id order by order_date desc) as rnk
from (select s.customer_id, order_date, product_id, join_date
from dannys_diner.sales AS s
left join dannys_diner.members AS mb
on s.customer_id = mb.customer_id) as mem_table
left join dannys_diner.menu AS m
ON mem_table.product_id = m.product_id
where order_date < join_date)

select customer_id, order_date, product_name, rwn, rnk
from cte
where rwn = 1;

--Q8 What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(product_name) as total_item, sum(price) as total_amount_spent
from dannys_diner.sales AS s
left join dannys_diner.members AS mb
on s.customer_id = mb.customer_id
inner join dannys_diner.menu as m on s.product_id = m.product_id
where join_date > order_date
group by s.customer_id;

--Q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?
with CTE AS (select s.customer_id, product_name, price,
case
	when product_name = 'sushi' then 2*(price * 10)
	Else price * 10
	End AS Purchase_points
from dannys_diner.sales AS s
left join dannys_diner.members AS mb
on s.customer_id = mb.customer_id
inner join dannys_diner.menu as m on s.product_id = m.product_id)

select customer_id, sum (purchase_points), product_name
from cte
group by customer_id, product_name;

/*Q 10 In the first week after a customer joins the program (including their join date) they earn 2x points 
on all items, not just sushi - how many points do customer A and B have at the end of January? */

with cte AS (select *,
case 
when new_date > 1 then price * 20
when new_date = 0 then price * 20
when new_date > 7 then price * 10
when product_name = 'sushi' then price * 20
Else price * 10
End AS Purchase_points
from (select s.customer_id, product_name, order_date, join_date, price, (order_date - join_date) as new_date
	  from dannys_diner.sales AS s
left join dannys_diner.members AS mb
on s.customer_id = mb.customer_id
inner join dannys_diner.menu as m on s.product_id = m.product_id
) as point_table)

select customer_id, sum(purchase_points), count (product_name)
from cte
where order_date between '2021-01-01' AND '2021-01-31'
AND customer_id between 'A' AND 'B'
group by customer_id;