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

create index idx_film_specials on film(special_features);
drop index idx_film_specials;

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


select count(customer_id) number_view
	from customer_films_with_bts cfwb;


--- 2.b. Materialized view. Version 1.0:

create materialized view customer_films_with_bts_upd
	as
	select r.customer_id,
			count(r.customer_id) films_with_bts
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
		group by customer_id
		order by customer_id
	with no data;


refresh materialized view customer_films_with_bts_upd;


select *
	from customer_films_with_bts_upd cfwb1;

select count(customer_id) number_view_upd
	from customer_films_with_bts_upd cfwb1;


---- Compare v.0.1 and v.1.0:

select customer_id id_delta,
	films_with_bts bts_delta
	from customer_films_with_bts cfwb
	full outer join customer_films_with_bts_upd cfwb1 using(customer_id, films_with_bts)
	where cfwb.customer_id is null 
		or cfwb1.customer_id is null;

select customer_id id_delta,
	films_with_bts bts_delta,
	'not in view bts' as delta_note
	from customer_films_with_bts cfwb
	except 
		select customer_id id_delta,
	films_with_bts bts_delta,
	'not in view bts' as delta_note
	from customer_films_with_bts_upd cfwb1
union
select customer_id id_delta,
	films_with_bts bts_delta,
	'not in view bts_upd' as delta_note
	from customer_films_with_bts_upd cfwb1
	except 
		select customer_id id_delta,
	films_with_bts bts_delta,
	'not in view bts_upd' as delta_note
	from customer_films_with_bts cfwb;
	


--- 2.c. Explain results:


-- cost = 1,537.12, rows = 863, width = 10;
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
--	order by customer_id
	;

/*

1. Для выполнения скрипта, PostgreSQL в первую очередь вынужден обработать внутренний запрос на последовательное включение 538 значений массивов с "Behind the Scenes", включенных в колонку "special_features" в таблице с фильмами, в хеш-таблицу для последующий операций.
Стоимость обработки данного запроса - 76,5.
Результат сохраняется в хэш-таблицу для последующих операций.
1.1. Параллельно PostgreSQL последовательно считывает имеющиеся значения "film_id" в 4.581 строках таблицы инвентаря (стоимость операции - 70,81 единиц ресурсов).
1.2. Параллельно PostgreSQL последовательно сканирует 16.044 строк записей в поисках значений "inventory_id" (что стоит 310,44 условных единиц мощности).

2. Затем СУБД приступает к выполнению операции соединения полученной отфильтрованной хэш-таблицы с инвентаризированными товарами в таблице "inventory". 
Полученные на шаге 1.1 данные соотносятся со значениями в одноименном столбце хэш-таблицы "film" и производится объединение 2,465 строк, соответствующих критериям, что начинается с 83,22 и от начала до данного этапа стоит 195,86.
Результат сохраняется в виде хэш-таблицы для последующих операций.

3. Затем СУБД приступает к выполнению операции соединения имеющейся хэш-таблицы с инвентаризированными товарами, отфильтрованным списом фильмов с записями об аренде, расположенными в таблице "rental". 
Полученные на шаге 1.2 данные соотносятся со значениями в одноименном столбце хэш-таблицы, полученной по итогам шага №2, и производится объединение совпадающих значений в 8,632 строках, что начинается с 226,68 и требует от начала до данного этапа 683,61 единиц ресурсов.
Результат сохраняется в виде хэш-таблицы для последующих операций.

4. Для применения оконной функции с разделением по "customer_id", СУБД предварительно сортирует данные хэш-таблицы с инвентаризированными товарами, отфильтрованным списом фильмов и записями об аренде, состоящей из 8.632 строк, по указанному столбцу.
От начала работа скрипта к момента завершения данной операции затрачено 1.269,53 единиц ресурсов от компутационного времени выполнения всего скрипта.
После успешной сортировки выполняется оконная функция (подсчет количества арендованных фильмов, включающих "Behind the Scenes" для каждого покупателя).
Общая стомость выполнения скрипта увеличивается до 1.399,01, в то время как количество рядов данных в хеш-таблице не изменяется.

5. Финальным этапом данного скрипта становится группировка данных временной хэш-таблицы по столбцам "customer_id" и "count(inventory_id).
Результирующая таблица включает в себя 863 строки.
Итоговая стоимость скрипта составляет 1.537,12.

Отмечу, что возможная итоговая сортировка полученной таблицы по столбцу "customer_id" будет стоить 44,24 (как видно из разницы итоговой стоимости работы скрипта с сортировкой и без нее).

*/


-- cost = 732.76, rows = 599, width = 12;
explain
select r.customer_id,
		count(r.customer_id) films_with_bts
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
	group by customer_id
--	order by customer_id
	;

/*


*/


-- cost = 1,952.22, rows = 901, width = 10;
explain (format json)
with cte_specials as (
	select f.film_id,
		f.special_features
	from film f
	where 'Behind the Scenes' = any(f.special_features)
),
cte_inventory as (
	select i.inventory_id,
		i.film_id 
	from inventory i
	join cte_specials using (film_id)
),
cte_customer as (
	select r.customer_id,
		count(r.inventory_id) over (partition by r.customer_id) films_with_bts
	from rental r
	join cte_inventory using (inventory_id)
)
select cte_customer.customer_id,
	cte_customer.films_with_bts
	from cte_customer
	group by customer_id, films_with_bts
	order by customer_id;



-- cost = 2,131.48, rows = 901, width = 10;
explain
with cte_specials as (
	select f.film_id,
		f.special_features
	from film f
	where 'Behind the Scenes' = any(f.special_features)
),
cte_inventory as (
	select i.inventory_id
	from inventory i
	join cte_specials using (film_id)
),
cte_customer as (
	select r.customer_id,
		r.inventory_id 
	from rental r
	join cte_inventory using (inventory_id)
),
cte_customer_with_bts as (
	select customer_id,
		count(inventory_id) over (partition by customer_id) films_with_bts
	from cte_customer
)
select cte_customer_with_bts.customer_id,
	cte_customer_with_bts.films_with_bts
	from cte_customer_with_bts
	group by customer_id, films_with_bts
	order by customer_id;




-- cost = 165,715.54, rows = 40,000, width = 10;
explain

with cte_specials as (
	select f.film_id,
		f.special_features
	from film f
	where 'Behind the Scenes' = any(f.special_features)
),
cte_inventory as (
	select i.inventory_id,
		i.film_id 
	from inventory i
),
cte_customer as (
	select r.customer_id,
		r.inventory_id 
	from rental r 
)

select customer_id,
	 films_with_bts
	from (
		select customer_id,
			count(inventory_id) over (partition by customer_id) films_with_bts
		from cte_customer
	join (
		select inventory_id
		from cte_specials
		join cte_inventory using(film_id)
	) as inventory_with_specials using(inventory_id)
	) as customer_count
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
	


--- Simpliest query:
explain analyze
select r.customer_id,
	count(inventory_id) films_rented
	from rental r
	left join inventory i using (inventory_id)
	left join film f using (film_id)
	where 'Behind the Scenes' = any(f.special_features)
	group by customer_id;

select distinct cu.first_name || ' ' || cu.last_name as customer_name,
	count(r.inventory_id) films_rented
	from customer cu
	left join rental r using (customer_id)
	left join inventory i using (inventory_id)
	left join film f using (film_id)
	where 'Behind the Scenes' = any(f.special_features)
	group by cu.first_name, cu.last_name;