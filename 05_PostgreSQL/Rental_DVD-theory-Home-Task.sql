-- 	1. Rental - window function:

select
	row_number() over (partition by customer_id order by rental_date) customer_rental,
	*
	from rental
	order by customer_id;


-- 2. Behind the Scenes - materialized view with explain:

--- 2.a. Query:

select cu.customer_id,
	cu.films_with_bts
	from (
		select r.customer_id,
			count(r.inventory_id) over (partition by r.customer_id) films_with_bts
		from rental r
		join (
			select i.inventory_id,
			i.film_id 
			from inventory i
			join (
				select f.film_id,
				f.special_features
				from film f
				where 'Behind the Scenes' = any(f.special_features)
			) as films using (film_id)
		) as films using (inventory_id)
	) as cu
	group by customer_id, films_with_bts
	order by customer_id;


--- 2.b. Materialized view:

create materialized view customer_films_with_bts
	as select cu.customer_id,
		cu.films_with_bts
		from (
			select r.customer_id,
				count(r.inventory_id) over (partition by r.customer_id) films_with_bts
			from rental r
			join (
				select i.inventory_id,
				i.film_id 
				from inventory i
				join (
					select f.film_id,
					f.special_features
					from film f
					where 'Behind the Scenes' = any(f.special_features)
				) as films using (film_id)
			) as films using (inventory_id)
		) as cu
		group by customer_id, films_with_bts
		order by customer_id
	with no data;

refresh materialized view customer_films_with_bts;

select *
	from customer_films_with_bts cfwb;



--- 2.c. Explain results:

explain
select cu.customer_id,
	cu.films_with_bts
	from (
		select r.customer_id,
			count(r.inventory_id) over (partition by r.customer_id) films_with_bts
		from rental r
		join (
			select i.inventory_id,
			i.film_id 
			from inventory i
			join (
				select f.film_id,
				f.special_features
				from film f
				where 'Behind the Scenes' = any(f.special_features)
			) as films using (film_id)
		) as films using (inventory_id)
	) as cu
	group by customer_id, films_with_bts
	order by customer_id;




--- Behind the Scenes:

select f.film_id,
	f.special_features
	from film f
	where 'Behind the Scenes' = any(f.special_features);


--- Film to inventory:

select i.inventory_id,
	i.film_id 
	from inventory i;
	

--- Customer to inventory:

select r.customer_id,
	r.inventory_id 
	from rental r ;
	
