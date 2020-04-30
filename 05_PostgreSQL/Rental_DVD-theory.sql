-- Window functions:

select 
	f.title film_title,
	a.first_name || ' ' || a.last_name actor_name,
	sum(fa.actor_id) over (partition by fa.actor_id)  num_of_films
	from actor a
	join film_actor fa using (actor_id)
	join film f using (film_id);
	

-- Common Table Expressions (CTE):

with cte_sold as (
	select staff_id,
		count(inventory_id) sold_total
		from rental
		group by staff_id 
)
select staff_id,
		first_name || ' ' || last_name staff_name,
		sold_total
	from staff s
	join cte_sold using(staff_id)
;


-- Views:

create view customer_last_rental as
	select inventory_id,
		film_title.title last_rental_title,
		first_name || ' ' || last_name || ', email: ' || email customer,
		customer_id
	from customer c
	join (
		select customer_id,
			inventory_id,
			last_rental_date
		from (
			select customer_id,
				rental_date,
				max(rental_date) over (partition by customer_id) last_rental_date,
				inventory_id 
			from rental
		) as last_rental
		where last_rental_date = rental_date
	) as rental using (customer_id)
	join (
		select inventory_id,
			title
		from film
		join inventory using (film_id)
	) as film_title using (inventory_id)
	order by customer;