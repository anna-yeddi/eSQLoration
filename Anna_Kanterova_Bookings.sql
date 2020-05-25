
-- В каких городах больше одного аэропорта?

select 
	count(city) num_of_airports,
	city ->> 'en' city_name
from airports_data ad 
group by city
having count(city) > 1;





-- В каких аэропортах есть рейсы, которые обслуживаются самолетами с максимальной дальностью перелетов?

---  В данной БД создание индекса не сработает, т.к. недостаточно прав, но могло бы ускорить несколько запросов.
create index on flights(aircraft_code);

select 
	distinct f.departure_airport airport_code,
	ad.airport_name ->> 'en' airport_name
from flights f 
left join airports_data ad on ad.airport_code = f.departure_airport
where f.aircraft_code = (
	select 
		acd.aircraft_code
	from aircrafts_data acd 
	where acd."range" = (
		select
			max(acd."range")
		from aircrafts_data acd 
	)
);




---- Drafts:
--- Airport name:
select 
	ad.airport_code,
	ad.airport_name ->> 'en' airport_name
from airports_data ad ;

--- Flights:
select 
	f.departure_airport,
	f.arrival_airport,
	f.aircraft_code 
from flights f ;

--- Max aircraft range:
select 
	acd.aircraft_code,
	acd.model ->> 'en' aircraft_model,
	acd."range" aircraft_range
from aircrafts_data acd 
where acd."range" = (
	select
		max(acd."range")
	from aircrafts_data acd 
);

--- Longer solution:
with cte_aircraft as (
	select 
		acd.aircraft_code,
		acd.model ->> 'en' aircraft_model
	from aircrafts_data acd 
	where acd."range" = (
		select
			max(acd."range")
		from aircrafts_data acd 
	)
)
select 
	distinct f.departure_airport airport_code,
	ad.airport_name ->> 'en' airport_name,
	ca.aircraft_model
from flights f 
right join cte_aircraft ca using (aircraft_code)
left join airports_data ad on ad.airport_code = f.departure_airport
order by airport_code;






-- Были ли брони, по которым не совершались перелеты?
-- НЕТ

select 
	b.book_ref,
	t.ticket_no
from bookings b
left join tickets t using (book_ref)
where ticket_no is null;




-- Самолеты каких моделей совершают наибольший % перелетов?
-- Cessna 208 Caravan, 28,01%
-- Bombardier CRJ-200, 27,29%
-- Sukhoi Superjet-100б 25,69%

select
	ad.aircraft_code,
	ad.model ->> 'en' aircraft,
	flights.aircraft_flights,
	flights.percents
from aircrafts_data ad
left join (
	select 
	 	aircraft_code,
		count(aircraft_code) aircraft_flights,
		round((count(*) / (sum(count(*)) over() ) * 100), 2) percents
	from flights f
	group by aircraft_code
) as flights using (aircraft_code)
where aircraft_flights is not null 
	and percents > 20
order by aircraft_flights desc;



---- Drafts:

explain analyze

with cte_flights as (
	select 
	 	aircraft_code,
		count(aircraft_code) aircraft_flights,
		(count(*) / (sum(count(*)) over() )) * 100 percents
	from flights f
	group by aircraft_code
)
select
	ad.aircraft_code,
	ad.model ->> 'en' aircraft,
	cte_flights.aircraft_flights,
	cte_flights.percents
from aircrafts_data ad
left join cte_flights using (aircraft_code)
where aircraft_flights is not null 
order by aircraft_flights desc




explain analyze

with cte_flights as (
	select 
	 	aircraft_code,
		count(aircraft_code) aircraft_flights
	from flights f
	group by aircraft_code
)
select
	ad.aircraft_code,
	ad.model ->> 'en' aircraft,
	cte_flights.aircraft_flights,
	percent_rank() over (order by aircraft_flights)
from aircrafts_data ad
left join cte_flights using (aircraft_code)
where aircraft_flights is not null 
order by aircraft_flights desc;




explain analyze
select
	ad.aircraft_code,
	ad.model ->> 'en' aircraft,
	aircraft_flights
from aircrafts_data ad
left join (
	select 
	 	aircraft_code,
		count(aircraft_code) aircraft_flights
	from flights f
	group by aircraft_code
	order by aircraft_flights desc
) as fligts using (aircraft_code)
where aircraft_flights is not null 
order by aircraft_flights desc
limit 3;





-- Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом?


	select
		f.departure_airport,
		f.arrival_airport,
		tf.amount price,
		tf.fare_conditions
	from ticket_flights tf 
	left join flights f using (flight_id)
	group by fare_conditions, amount, arrival_airport, departure_airport
	order by arrival_airport

explain analyse 
with cte as (
	select
		aird.city,
		tf.amount price,
		tf.fare_conditions fare
	from ticket_flights tf 
	left join flights f using (flight_id)
	left join (
		select
			airport_code,
			city ->> 'en' city
		from airports_data apd 
	) as aird on f.arrival_airport = aird.airport_code
	group by city, fare_conditions, amount
	order by city
)
select
	city
from (
	select
		row_number() over (partition by city order by price) price_rating,
		city,
		fare
	from cte
) as cte_fare
where fare = 'Business' and price_rating = 3;



explain analyse 
with cte as (
	select
		f.arrival_airport,
		tf.amount price,
		tf.fare_conditions fare
	from ticket_flights tf 
	left join flights f using (flight_id)
	group by arrival_airport, fare_conditions, amount
)
select
	city ->> 'en' city
from (
	select
		row_number() over (partition by arrival_airport order by price) price_rating,
		arrival_airport,
		fare
	from cte
) as cte
left join airports_data apd on apd.airport_code = cte.arrival_airport
where fare = 'Business' and price_rating = 3;







-- Узнать максимальное время задержки вылетов самолетов

select
	max(actual_departure - scheduled_departure) as max_delay
	from flights f 
	where actual_departure is not null;


---- Draft:

select
	scheduled_departure,
	actual_departure,
	(actual_departure - scheduled_departure) as delay
	from flights f 
	where actual_departure is not null;




-- Между какими городами нет прямых рейсов*?


select
	f.departure_airport,
	a1.city ->> 'en' city,
	f.arrival_airport,
	a.city ->> 'en' city
	from flights f 
	left join airports_data a on f.arrival_airport = a.airport_code 
	left join airports_data a1 on f.departure_airport = a1.airport_code 



with cte as (
	select
		f.departure_airport airport1,
		f.arrival_airport airport2
	from flights f 
	union 
	select
		f.arrival_airport airport1,
		f.departure_airport airport2
	from flights f
)
select
	a1.city ->> 'en' city1,
	a2.city ->> 'en' city2
from cte
left join airports_data a1 on cte.airport1 = a1.airport_code 
left join airports_data a2 on cte.airport2 = a2.airport_code 
group by city1, city2
order by city1

--- List of connected cities:
with cte as (
	select
		airport_code code,
		city ->> 'en' city
	from airports_data apd 
)
select
	cte1.city city1,
	cte2.city city2
from flights f 
left join cte as cte1 on cte1.code = f.departure_airport 
left join cte as cte2 on cte2.code = f.arrival_airport 
group by city1, city2



with cte as (
	select
		airport_code code,
		city ->> 'en' city
	from airports_data apd 
),
cte_city as (
	select
		cte1.city city1,
		cte2.city city2
	from flights f 
	left join cte as cte1 on cte1.code = f.departure_airport 
	left join cte as cte2 on cte2.code = f.arrival_airport 
	group by city1, city2
),
cte_city_list as (
	select 
		distinct city ->> 'en' city
	from airports_data apd
	order by city
)
select
	*
from cte_city ct




---- Drafts:

select
	*
from airports_data apd 

select
	*
from aircrafts_data ad 

select
	*
from flights f 
	
select
	*
from ticket_flights tf 
	
select
	*
from boarding_passes bp 


-- Между какими городами пассажиры делали пересадки*?



-- Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы **

--- Кратчайшее расстояние между двумя точками A и B на земной поверхности (если принять ее за сферу) определяется зависимостью:
---- d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}, где latitude_a и latitude_b — широты, longitude_a, longitude_b — долготы данных пунктов, d — расстояние между пунктами, измеряемое в радианах длиной дуги большого круга земного шара.
--- Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
---- L = d·R, где R = 6371 км — средний радиус земного шара.
--- Для расчета расстояния между пунктами, расположенными в разных полушариях (северное-южное, восточное-западное) , знаки (±) у соответствующих параметров (широты или долготы) должны быть разными. 

