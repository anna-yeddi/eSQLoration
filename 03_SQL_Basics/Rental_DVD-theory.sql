-- 1.1. All movies with language:
select f.title film_title,
	l."name" film_language,
	f.language_id film_lang_id,
	l.language_id film_language_id
	from "language" l 
	inner join film f on f.language_id = l.language_id
	order by film_language desc, film_title;
	
-- 1.2. All actors from Lambs Cincinatti (id=508):
select f.film_id as film_id_f,
	f.title as film_title,
	a.first_name || ' ' || a.last_name as film_actor,
	a.actor_id as film_actor_id_a,
	fa.actor_id as film_actor_id,
	fa.film_id as film_id
	from film f
	inner join film_actor fa on f.film_id = fa.film_id
	inner join actor a on a.actor_id = fa.actor_id
	where fa.film_id = 508
	order by film_actor desc, film_title;

-- 2. Number of actors from Grosse Wonderful (id=384):
select count(distinct fa.actor_id)
	from film_actor fa 
	where fa.film_id = 384;
	
-- 3. List of movies with more than 10 actors:
select
	f.title film_title,
	count(*) actors
	from film_actor fa
	inner join film f on f.film_id = fa.film_id 
	group by f.title
	having count(f.title) > 10
	order by actors desc;


-- 4. Film title, name of actor, number of movies:

--- Step 1: Actors with names and movies:
select fa.film_id,
	a.first_name || ' ' || a.last_name actor_name,
	count(fa.film_id) over (partition by fa.actor_id) actor_films
	from film_actor fa
	inner join actor a on a.actor_id = fa.actor_id;

--- Step 2: Films
select f.title film_title
	from film f
	inner join film_actor fa on f.film_id = fa.film_id	

--- Practice 4 data set:
select fa_id.film_title,
	a.first_name || ' ' || a.last_name actor_name,
	count(fa_id.film_title) over (partition by fa_id.actor_id) actor_films
	from (
		select f.title film_title,
			fa.actor_id actor_id
		from film f
		inner join film_actor fa on f.film_id = fa.film_id
		) as fa_id
	inner join actor a on a.actor_id = fa_id.actor_id
	order by film_title;


-- Practice Class 2020-04-24:

--- Films and categories:
select c."name" as category, f.title as film, f.description
	from film_category fc
	join film f on f.film_id = fc.film_id
	join category c on fc.category_id = c.category_id
	order by title desc;	
	
--- Stores from city id=576:
select s.store_id as store, a.address, c.city, ct.country 
	from address a
	join city c on c.city_id = a.city_id
	join store s on s.address_id = a.address_id
	join country ct on ct.country_id = c.country_id
	where c.city_id = 576;
	
--- Avg rental rate:
select 
	round(avg(f.rental_rate / f.rental_duration), 2) as avg_daily_rent
	from film f;
	

--- Films and categories that start with C:
select c."name" as category, f.title as film, f.description
	from film_category fc
	join film f on f.film_id = fc.film_id
	join category c on fc.category_id = c.category_id
	where c."name" like 'C%'
	order by title desc;
	
select f.title, f.description
	from film f
	join film_category fc using(film_id)
	where fc.category_id in (select c.category_id from category c
								where c."name" like 'C%');

select f.title, f.description, c."name" as cat_name
from film f 
join film_category fc on f.film_id = fc.film_id 
join (select * from category c 
	where c."name" like 'C%'
) c on fc.category_id = c.category_id 
order by f.film_id 
​
​
​
​
select f.title, f.description
from film f 
where f.film_id in (select distinct fc.film_id 
						from category c 
						join film_category fc on fc.category_id = c.category_id 
						where c."name" like 'C%');
							
select f.title, f.description
	from film f
	where f.film_id in (select distinct fc.film_id
							from category c
							join film_category fc using(category_id)
							where c."name" like 'C%');