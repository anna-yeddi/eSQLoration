-- List of all tables:
select distinct tablename 
	from pg_catalog.pg_tables pt
	where schemaname = 'public';

-- All tables and PKs:
select table_name as TableName,
	constraint_name as PrimaryKey
	from information_schema.table_constraints tc  
	where constraint_type = 'PRIMARY KEY'
	and table_schema = 'public'
	order by TableName;

-- Inactive users:
select distinct first_name, last_name, last_update,
	active as IsInactive
	from customer c 
	where active = '0';

-- Inactive users (after a feedback):
select distinct first_name, last_name, last_update,
	active as IsInactive
	from customer c 
	where active = 0;

-- Last 10 payments:
select payment_date, amount, payment_id, customer_id, rental_id 
	from payment p 
	order by payment_date desc 
	limit 10;