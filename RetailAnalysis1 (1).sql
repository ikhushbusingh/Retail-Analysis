select * from login_logs
select * from sales_orders
select * from sales_orders_items

--1. Make a dataset (Using SQL) named “daily_logins” which contains the number of logins on a daily basis
select CAST(login_time as date) as Date , COUNT(login_log_id) as daily_login_count
from login_logs
group by CAST(login_time as date)
order by Date;

-- 2. Daily trend of logins and trend of conversion rate (Number of orders placed per login)
-- ct1 query to find daily number of logins order by date
-- cte2 is to find daily order placed irrespective or rejected or shipped
with cte1 as (
select Convert(date, login_time) as Date , COUNT(login_log_id) as daily_login_count
from login_logs
group by CAST(login_time as date)
	),
	cte2 as (
	select CONVERT(date, creation_time) as Date, COUNT(order_id) as order_placed
	from sales_orders
	group by CONVERT(date, creation_time)
	)  select cte1.Date, daily_login_count, order_placed, cast(order_placed*1.0/daily_login_count*100 as decimal(20,2)) as conversion_rate
	from cte1
	join cte2 on cte1.Date = cte2.Date
	order by Date;

-- 3. Prepare a report regarding our growth between the 2 years. Please try to answer the following questions:
-- a. Did our business grow?
with cte1 as (
select YEAR(creation_time) as Year, CAST(SUM(order_quantity_accepted*rate) as decimal(20,2)) as total_order_amount
from sales_orders so
join sales_orders_items soi on so.order_id = soi.fk_order_id
group by YEAR(creation_time) ), cte2 as (
	select 'total_order_amount' as ' ',
	MAX(case when Year = 2021 then total_order_amount end) as '2021',
	MAX(case when Year = 2022 then total_order_amount end) as '2022'
	from cte1 )
		select * , ([2022]-[2021])/[2021]*100 as percentage_increase
		from cte2;
-- b. checking number of customer increased

with cte1 as (
select YEAR(login_time) as 'Year', COUNT(distinct USER_ID) as no_of_user_login from login_logs
where YEAR(login_time) = 2021
group by YEAR(login_time)
union all
select YEAR(login_time) as 'Year', COUNT(distinct USER_ID) as no_of_user_login from login_logs
where YEAR(login_time) = 2022
group by YEAR(login_time) ), 
cte2 as (
select YEAR(login_time) as 'Year', COUNT(distinct USER_ID) as no_of_user_ordered
from login_logs ll
join sales_orders so on ll.user_id = so.fk_buyer_id
join sales_orders_items soi on soi.fk_order_id = so.order_id
where YEAR(login_time) = 2021
group by YEAR(login_time)
union all
select YEAR(login_time) as 'Year', COUNT(distinct USER_ID) as no_of_user_ordered
from login_logs ll
join sales_orders so on ll.user_id = so.fk_buyer_id
join sales_orders_items soi on soi.fk_order_id = so.order_id
where YEAR(login_time) = 2022
group by YEAR(login_time) )
select cte1.Year, no_of_user_login, no_of_user_ordered, CAST((no_of_user_ordered*1.0/no_of_user_login*100) as decimal(20,2)) percentage_orderd
from cte1
join cte2 on cte1.Year = cte2.Year;

-- query for finding number of logins, unqique user login, number of user logined, percentage of ordered
with cte1 as (
select YEAR(login_time) as 'Year', COUNT(login_log_id) as login_count,  COUNT(distinct USER_ID) as no_of_user_login from login_logs
where YEAR(login_time) = 2021
group by YEAR(login_time)
union all
select YEAR(login_time) as 'Year', COUNT(login_log_id) as login_count, COUNT(distinct USER_ID) as no_of_user_login from login_logs
where YEAR(login_time) = 2022
group by YEAR(login_time) ), 
cte2 as (
select YEAR(login_time) as 'Year', COUNT(distinct USER_ID) as no_of_user_ordered
from login_logs ll
join sales_orders so on ll.user_id = so.fk_buyer_id
join sales_orders_items soi on soi.fk_order_id = so.order_id
where YEAR(login_time) = 2021
group by YEAR(login_time)
union all
select YEAR(login_time) as 'Year', COUNT(distinct USER_ID) as no_of_user_ordered
from login_logs ll
join sales_orders so on ll.user_id = so.fk_buyer_id
join sales_orders_items soi on soi.fk_order_id = so.order_id
where YEAR(login_time) = 2022
group by YEAR(login_time) )
select cte1.Year, login_count, no_of_user_login, no_of_user_ordered, CAST((no_of_user_ordered*1.0/no_of_user_login*100) as decimal(20,2)) percentage_orderd
from cte1
join cte2 on cte1.Year = cte2.Year

--b. Does our app perform better now?

select YEAR(login_time) as Year, COUNT(distinct(user_id)) as unique_customers#
from login_logs
group by YEAR(login_time)
order by YEAR(login_time);

with cte1 as (
select * ,
MIN(login_time) over (partition by user_id) as first_login
from login_logs )
	select YEAR(login_time) as Year, COUNT(distinct(user_id)) as new_customers#
	from cte1
	where YEAR(login_time) = 2022 and YEAR(first_login) = 2022
	group by YEAR(login_time);

with cte1 as (
select * ,
MIN(login_time) over (partition by user_id) as first_login
from login_logs )
	select YEAR(login_time) as Year, COUNT(distinct(user_id)) as old_customers#
	from cte1
	where YEAR(login_time) = 2022 and YEAR(first_login) = 2021
	group by YEAR(login_time);


-- 4. What are our top-selling products in each of the two years? Can you draw some insight from this?
--select *
--from sales_orders so
--join sales_orders_items soi on so.order_id = soi.fk_order_id
-- top selling product quantity wise
select YEAR(creation_time) as Year, fk_product_id as productID, SUM(order_quantity_accepted) as number_of_products
from sales_orders so
join sales_orders_items soi on so.order_id = soi.fk_order_id
group by YEAR(creation_time), fk_product_id
order by Year, number_of_products desc;

-- top selling product revenaue wise
select YEAR(creation_time) as Year, fk_product_id as productID, CAST(SUM(order_quantity_accepted*rate) as decimal(20,2)) as total_order_amount
from sales_orders so
join sales_orders_items soi on so.order_id = soi.fk_order_id
group by YEAR(creation_time), fk_product_id
order by Year, total_order_amount desc;
-- top selling product number wise and revenue wise
select YEAR(creation_time) as Year, fk_product_id as productID, SUM(order_quantity_accepted) as number_of_products, 
CAST(SUM(order_quantity_accepted*rate) as decimal(20,2)) as total_order_amount
from sales_orders so
join sales_orders_items soi on so.order_id = soi.fk_order_id
group by YEAR(creation_time), fk_product_id
order by year, number_of_products desc, total_order_amount desc;
-- top selling products year wise (pivot table)
with cte1 as (
select YEAR(creation_time) as Year, fk_product_id as productID, SUM(order_quantity_accepted) as number_of_products
from sales_orders so
join sales_orders_items soi on so.order_id = soi.fk_order_id
group by YEAR(creation_time), fk_product_id )
	select top 20 ProductID,
	SUM(case when Year = 2021 then number_of_products else 0 end) as '2021',
	SUM(case when Year = 2022 then number_of_products else 0 end) as '2022'
	from cte1
	group by ProductID
	order by [2021] desc;

-- 5. Looking at July 2021 data, what do you think is our biggest problem and how would you recommend fixing it?
select * 
from login_logs ll
join sales_orders so on ll.user_id = so.fk_buyer_id
join sales_orders_items soi on soi.fk_order_id = so.order_id
where YEAR(login_time) = 2021

-- 6. Does the login frequency affect the number of orders made?
select user_id, COUNT(login_log_id) as login_count
from login_logs
group by user_id
order by user_id

select fk_buyer_id as user_id, COUNT(order_id) as order_count
from sales_orders
group by fk_buyer_id
order by user_id

select user_id, COUNT(login_log_id) as login_count, COUNT(order_id) as order_count
from login_logs ll
join sales_orders so on ll.user_id = so.fk_buyer_id
group by user_id
order by user_id

select user_id, login_log_id as login_count, order_id as order_count
from login_logs ll
left join sales_orders so on ll.user_id = so.fk_buyer_id
order by user_id

with cte1 as (
select user_id, COUNT(login_log_id) as login_count
from login_logs
group by user_id ), cte2 as (
	select fk_buyer_id as user_id, COUNT(order_id) as order_count
	from sales_orders
	group by fk_buyer_id )
		select cte1.user_id, login_count, order_count
		from cte1
		left join cte2 on cte1.user_id = cte2.user_id
		order by cte1.user_id;

with cte1 as (
select user_id, COUNT(login_log_id) as login_count
from login_logs
group by user_id ), cte2 as (
	select fk_buyer_id as user_id, COUNT(order_id) as order_count, 
	CAST(SUM(order_quantity_accepted*rate) as decimal(20,2)) as total_order_amount
	from sales_orders so
	join sales_orders_items soi on so.order_id = soi.fk_order_id
	group by fk_buyer_id )
		select cte1.user_id, login_count, isnull(order_count, 0) as order_count, ISNULL(total_order_amount, 0.00) as total_order_amount,
		ISNULL(order_count*1.0/login_count, 0.00) as ratio
		from cte1
		left join cte2 on cte1.user_id = cte2.user_id
		order by ratio desc;

select fk_buyer_id as user_id, COUNT(order_id) as order_count, 
CAST(SUM(order_quantity_accepted*rate) as decimal(20,2)) as total_order_amount
from sales_orders so
join sales_orders_items soi on so.order_id = soi.fk_order_id
group by fk_buyer_id;

-- Calculating date wise sales
with cte1 as (
select CAST(creation_time as date) as Date, Day(creation_time) as Day,  COUNT(distinct order_id) as no_of_orders,  SUM(order_quantity_accepted) as no_of_products, 
CAST(SUM(order_quantity_accepted*rate) as decimal(20,2)) as total_order_amount
from sales_orders as so
join sales_orders_items as soi on so.order_id = soi.fk_order_id
group by CAST(creation_time as date), Day(creation_time) )
	select Day, 
	SUM(case when YEAR(Date) = 2021 then no_of_orders end) as '2021_order_placed', 
	SUM(case when YEAR(Date) = 2022 then no_of_orders end) as '2022_order_placed',
	SUM(case when YEAR(Date) = 2021 then no_of_products end) as '2021_product_count',
	SUM(case when YEAR(Date) = 2022 then no_of_products end) as '2022_product_count',
	SUM(case when YEAR(Date) = 2021 then total_order_amount end) as '2021_total_order_amount',
	SUM(case when YEAR(Date) = 2022 then total_order_amount end) as '2022_total_order_amount'
	from cte1
	group by Day
	order by Day;




select COUNT(distinct order_id)
from sales_orders
where YEAR(creation_time) = 2021


