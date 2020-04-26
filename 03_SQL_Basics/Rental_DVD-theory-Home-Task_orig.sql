-- sbs.manager = "Jon Stephens"
-- s.manager_staff_id = 1
-- s.store_id = 1
-- s.address_id = 1
-- sbs.store = "Woodridge, Au"	
-- sl.sid = 1
-- sl.name = "Jon Stephens"

-- Pt.1. Stores with address:
select sbs.store store_location,
	sl.sid store_id
	from sales_by_store sbs
	inner join staff_list sl on sbs.manager = sl.name

-- Pt.2 Stores with customers:
select cl.sid store_id,
	count(cl.sid) store_customers
	from customer_list cl 
	group by cl.sid

	
-- 1.a. Stores with more than 300 customers (from customer_list table):
select sbs.store store_location,
	customers.store_customers
	from sales_by_store sbs
	inner join staff_list sl on sbs.manager = sl.name
	inner join (
		select cl.sid store_id,
			count(cl.sid) store_customers
			from customer_list cl
			group by cl.sid
	) as customers on customers.store_id = sl.sid
	where store_customers > 300;
	
-- 1.b. Stores with more than 300 customers (from customer table):
select sbs.store store_location,
	customers.store_customers
	from sales_by_store sbs
	inner join staff_list sl on sbs.manager = sl.name
	inner join (
		select c.store_id store_id,
			count(c.store_id) store_customers
			from customer c
			group by c.store_id 
	) as customers on customers.store_id = sl.sid
	where store_customers > 300;
	
-- 2. Customers location:
select cl.city customer_city,
	cl.id customer_id,
	cl.name customer_name
	from customer_list cl
	order by customer_city
	