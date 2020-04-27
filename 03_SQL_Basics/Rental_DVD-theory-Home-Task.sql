-- Pt.1. Stores with address:
select sbs.store store_location,
	sl.sid store_id
	from sales_by_store sbs
	inner join staff_list sl on sbs.manager = sl."name"

-- Pt.2 Stores with customers:
select cl.sid store_id,
	count(cl.sid) store_customers
	from customer_list cl 
	group by cl.sid

	
-- 1.a. Stores with more than 300 customers (from customer_list table):
select sbs.store store_location,
	customers.store_customers
	from sales_by_store sbs
	inner join staff_list sl on sbs.manager = sl."name"
	inner join (
		select cl.sid store_id,
			count(cl.sid) store_customers
			from customer_list cl
			group by cl.sid
	) as customers on customers.store_id = sl.sid
	where store_customers > 300;

-- 1.b. Stores with more than 300 customers (with address):
select s.store_id, cust.numb as customers, a.address, c.city, ct.country 
	from address a
	join city c on c.city_id = a.city_id
	join store s on s.address_id = a.address_id
	join country ct on ct.country_id = c.country_id
	join (
		select cl.sid as store_id,
			count(cl.sid) as numb
			from customer_list cl 
			group by cl.sid 
	) as cust on cust.store_id = s.store_id
	where cust.numb > 300;


-- 2. Customers location:
select cl.city customer_city,
	cl.id customer_id,
	cl."name" customer_name
	from customer_list cl
	order by customer_city;
	


-- 2.1. Customers location (tables only):
select distinct c.customer_id,
	c.first_name || ' ' || c.last_name customer_name,
	ct.city, a.district, co.country
	from customer c
	join address a using(address_id)
	join city ct using(city_id)
	join country co using(country_id)
	order by city;

-- 1.1. Stores with more than 300 customers (tables only):
select distinct s.store_id,
	a.address || ', ' || ct.city || ', ' || a.district || ', ' || co.country as store_address
	from store s
	join address a using(address_id)
	join city ct using(city_id)
	join country co using(country_id)
	where s.store_id in (select c.store_id
							from customer c
							group by c.store_id
							having count(distinct c.customer_id) > 300);