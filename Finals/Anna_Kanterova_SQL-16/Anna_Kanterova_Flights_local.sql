set search_path = bookings;


-- Описание БД: https://docs.google.com/document/d/190CZu7qA4dpnN122N9I7EeG-1aQlDmVXH7dYzxdA6pA/edit?usp=sharing



-- 1. В каких городах больше одного аэропорта?

--- Москва (3 аэропорта)
--- Ульяновск (2 аэропорта)

--- Local DB:

select 
	count(city) num_of_airports,
	city city_name
from airports ap
group by city
having count(city) > 1;


--- Cloud DB (with JSONs):
select 
	count(city) num_of_airports,
	city ->> 'en' city_name
from airports_data ap
group by city
having count(city) > 1;






-- 2. В каких аэропортах есть рейсы, которые обслуживаются самолетами с максимальной дальностью перелетов?


--- Cloud DB (with JSONs):
---  В облачно подключенной БД создание индекса не сработает, т.к. недостаточно прав, но могло бы ускорить несколько запросов.
create index on flights(aircraft_code);

select 	distinct f.departure_airport airport_code,
		ad.airport_name ->> 'en' airport_name
from	flights f 
left join	airports_data ad on ad.airport_code = f.departure_airport
where	f.aircraft_code = (
	select 	acd.aircraft_code
	from	aircrafts_data acd 
	where	acd."range" = (
		select	max(acd."range")
		from 	aircrafts_data acd 
	)
);


--- Local DB:

create index on flights(departure_airport);

select 	distinct f.departure_airport airport_code,
		ap.airport_name airport_name
from	flights f 
left join	airports ap on ap.airport_code = f.departure_airport
where	f.aircraft_code = (
	select	ac.aircraft_code
	from	aircrafts ac
	where	ac."range" = (
		select	max(ac."range")
		from	aircrafts ac
	)
);




---- Draft:
---- Longer solution:
with cte_aircraft as (
	select	acd.aircraft_code,
			acd.model ->> 'en' aircraft_model
	from	aircrafts_data acd 
	where	cd."range" = (
		select	max(acd."range")
		from 	aircrafts_data acd 
	)
)
select	distinct f.departure_airport airport_code,
		ad.airport_name ->> 'en' airport_name,
		ca.aircraft_model
from	flights f 
right join	cte_aircraft ca using (aircraft_code)
left join	airports_data ad on ad.airport_code = f.departure_airport
order by	airport_code;






-- 3. Были ли брони, по которым не совершались перелеты?

-- ДА, 91.388

select	count(distinct book_ref)
from	(
	select	b.book_ref,
			bp.boarding_no,
			t.ticket_no
	from	bookings b
	left join	tickets t using (book_ref)
	left join	boarding_passes bp using (ticket_no)
	where	boarding_no is null
) as no_boardings;





-- 4. Самолеты каких моделей совершают наибольший % перелетов?

-- Cessna 208 Caravan, 28,01%
-- Bombardier CRJ-200, 27,29%
-- Sukhoi Superjet-100б 25,7%

select	ac.aircraft_code,
		ac.model aircraft,
		flights.aircraft_flights,
		flights.percents
from	aircrafts ac
left join	(
	select	aircraft_code,
			count(aircraft_code) aircraft_flights,
			round((count(*) / (sum(count(*)) over() ) * 100), 2) percents
	from	flights f
	group by aircraft_code
) as flights using (aircraft_code)
where	aircraft_flights is not null 
	and	percents > 20
order by aircraft_flights desc;




---- Drafts:
---- Cloud query versions:

with cte_flights as (
	select	aircraft_code,
			count(aircraft_code) aircraft_flights,
			(count(*) / (sum(count(*)) over() )) * 100 percents
	from	flights f
	group by aircraft_code
)
select	ad.aircraft_code,
		ad.model ->> 'en' aircraft,
		cte_flights.aircraft_flights,
		cte_flights.percents
from	aircrafts_data ad
left join 	cte_flights using (aircraft_code)
where		aircraft_flights is not null 
order by	aircraft_flights desc


with cte_flights as (
	select	aircraft_code,
			count(aircraft_code) aircraft_flights
	from	flights f
	group by aircraft_code
)
select	ad.aircraft_code,
		ad.model ->> 'en' aircraft,
		cte_flights.aircraft_flights,
		percent_rank() over (order by aircraft_flights)
from	aircrafts_data ad
left join 	cte_flights using (aircraft_code)
where 		aircraft_flights is not null 
order by 	aircraft_flights desc;


select	ad.aircraft_code,
		ad.model ->> 'en' aircraft,
		aircraft_flights
from	aircrafts_data ad
left join 	(
	select	aircraft_code,
			count(aircraft_code) aircraft_flights
	from	flights f
	group by aircraft_code
	order by aircraft_flights desc
) as fligts using (aircraft_code)
where 		aircraft_flights is not null 
order by 	aircraft_flights desc
limit 		3;







-- 5. Были ли города, в которые можно  добраться бизнес-классом дешевле, чем эконом-классом?

--- HET

select
		f.departure_airport,
		f.arrival_airport,
		tf.amount price,
		tf.fare_conditions
from	ticket_flights tf 
left join 	flights f using (flight_id)
group by 	fare_conditions, amount, arrival_airport, departure_airport
order by 	arrival_airport


---- Drafts:

---- Longer query - 19.1 sec:
-- explain analyse 
with cte as (
	select
			aird.city,
			tf.amount price,
			tf.fare_conditions fare
	from	ticket_flights tf 
	left join 	flights f using (flight_id)
	left join 	(
		select
				airport_code,
				city
		from	airports apd 
	) as aird on f.arrival_airport = aird.airport_code
	group by 	city, fare_conditions, amount
	order by 	city
)
select
		city, fare, price 
from	(
	select
			row_number() over (partition by city order by price) price_rating,
			city,
			price,
			fare
	from	cte
) as cte_fare
where	fare = 'Business' and price_rating = 1;


---- Faster query - 16.7 sec:
-- explain analyse 
with cte as (
	select
			f.arrival_airport,
			tf.amount price,
			tf.fare_conditions fare
	from	ticket_flights tf 
	left join 	flights f using (flight_id)
	group by 	arrival_airport, fare_conditions, amount
)
select
		city city
from	(
	select
			row_number() over (partition by arrival_airport order by price) price_rating,
			arrival_airport,
			fare
	from	cte
) as cte
left join 	airports apd on apd.airport_code = cte.arrival_airport
where		fare = 'Business' and price_rating = 1;








-- 6.Узнать максимальное время задержки вылетов самолетов

--- 4ч 37мин

select	max(age(actual_departure, scheduled_departure)) as max_delay
from	flights f 
where	actual_departure is not null;

--- Top 10 delays:

select	age(actual_departure, scheduled_departure) as delay,
		flight_no,
		departure_airport,
		arrival_airport 
from	flights f 
where		actual_departure is not null
order by	delay desc
limit		10;

select	max(actual_departure - scheduled_departure) as max_delay
from	flights f 
where	actual_departure is not null;







-- 7. Между какими городами нет прямых рейсов*?


select	df.departure_city || ' - ' || df.arrival_city as no_direct_flights
from  (
	select	a1.airport_code departure_airport,
			a1.city departure_city,
			a2.airport_code arrival_airport,
			a2.city arrival_city
	from	airports a1
	cross join 	(
		select	airport_code,
				city 
		from	airports
	) as a2
	where 		a1.city != a2.city 
) as df
where not exists 	(
	select
	from 	flights f
	where 	f.arrival_airport = df.arrival_airport
		and	f.departure_airport = df.departure_airport
)
order by	df.departure_city
limit		20;


--- Solution with CTE:

with cte as (
	select	a1.airport_code departure_airport,
			a1.city departure_city,
			a2.airport_code arrival_airport,
			a2.city arrival_city
	from	airports a1
	cross join 	(
		select	airport_code,
				city 
		from	airports
	) as a2
	where 	a1.airport_code != a2.airport_code 
)
select	cte.departure_airport,
		cte.arrival_airport
from cte
where not exists 	(
	select
	from 	routes r 
	where 	r.arrival_airport = cte.arrival_airport 
		and	r.departure_airport = cte.departure_airport
);









-- 8. Между какими городами пассажиры делали пересадки*?

create index on flights(flight_id);

with cte as (
	select	tf.ticket_no,
			f.departure_airport,
			f.scheduled_departure,
			f.arrival_airport,
			f.scheduled_arrival
	from	ticket_flights tf 
	left join	flights f using(flight_id)
)
select	a1.city || ' (' || l.departure_airport || ')' 
			|| ' - ' ||
			a2.city || ' (' || l.arrival_airport || ')' layovers_between_cities
from	(
	select	departure_airport,
			arrival_airport 
	from	(
		select	c1.ticket_no,
				c1.departure_airport departure_airport,
				c1.arrival_airport layover_airport,
				c1.scheduled_arrival layover_arrival,
				c2.scheduled_departure layover_departure,
				c2.arrival_airport arrival_airport
		from	cte c1
		left join	cte c2 on	c1.ticket_no = c2.ticket_no
							and	c1.arrival_airport = c2.departure_airport				
		where		c2.arrival_airport is not null
			and		age(c2.scheduled_departure, c1.scheduled_arrival) < make_interval(days => 1)
	) as layovers
	group by	departure_airport,
				arrival_airport 
) as l
left join	airports a1 on	l.departure_airport = a1.airport_code
left join	airports a2 on	l.arrival_airport = a2.airport_code;




---- Drafts:
---- Full layovers table:

with cte as (
	select	tf.ticket_no,
			tf.flight_id,
			f.departure_airport,
			f.scheduled_departure,
			f.arrival_airport,
			f.scheduled_arrival
	from	ticket_flights tf 
	left join	flights f using(flight_id)
)
select	c1.ticket_no,
		DATE_PART('day', c2.scheduled_departure - c1.scheduled_arrival) * 24 + 
    		DATE_PART('hour', c2.scheduled_departure - c1.scheduled_arrival) as delta_hrs,
		c1.flight_id,
		c1.departure_airport,
		c1.scheduled_departure,
		c1.arrival_airport,
		c1.scheduled_arrival,
		c2.flight_id,
		c2.scheduled_departure,
		c2.arrival_airport,
		c2.scheduled_arrival
from	cte c1
left join	cte c2 on	c1.ticket_no = c2.ticket_no
					and	c1.arrival_airport = c2.departure_airport
where		c2.arrival_airport is not null
	and		c1.scheduled_arrival < c2.scheduled_departure
	and		(
				select	DATE_PART('day', c2.scheduled_departure - c1.scheduled_arrival) * 24 + 
    					DATE_PART('hour', c2.scheduled_departure - c1.scheduled_arrival)
			) < 24;
		
		



		
		




-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы **


-- Option 1 (incl. custom function and amterialized view):

---- 1.1. Create a function to calculate a distance:

create or replace function distance (a_latitude float, a_longitude float, b_latitude float, b_longitude float)
returns int as $distance_km$
	declare
		distance_km float = 0;
		a_radlatitude float;
		b_radlatitude float;
		delta float;
		raddelta float;	
	begin 
		a_radlatitude = pi() * a_latitude / 180;
		b_radlatitude = pi() * b_latitude / 180;
		delta = a_longitude - b_longitude;
		raddelta = pi() * delta / 180;
		distance_km = sin(a_radlatitude) * sin(b_radlatitude) + cos(a_radlatitude) * cos(b_radlatitude) * cos(raddelta);
	
		if
			distance_km > 1
			then distance_km = 1;
		end if;
	
		distance_km = acos(distance_km) * 180 / pi();
		distance_km = distance_km * 60 * 1.1515;
		distance_km = distance_km * 1.609344;
		distance_km = distance_km::int;
	
		return distance_km;
	end;
$distance_km$ language plpgsql;


---- 1.2. Create mat.view with distance function for further references and practice:

create materialized view flights_distance as (
	select	
		distance(a_latitude, a_longitude, b_latitude, b_longitude) as distance_km,
		p.aircraft_range,
		p.aircraft_model,
		a_code departure_code,
		a_city_name departure_city,
		b_code arrival_code,
		b_city_name arrival_city,
		a_city || ' - ' || b_city route
	from (
		select	departure_airport,
				arrival_airport,
				aircraft_code
		from	flights fl
		group by departure_airport, arrival_airport, aircraft_code 
	) as f 
	left join (
		select	airport_code a_code,
	 			city || ' (' || airport_name || ', '|| airport_code || ')' a_city,
	 			city a_city_name,
	 			longitude a_longitude,
	 			latitude a_latitude
		from	airports ap
	) as a on f.departure_airport = a.a_code
	left join (
		select	airport_code b_code,
	 			city || ' (' || airport_name || ', '|| airport_code || ')' b_city,
	 			city b_city_name,
	 			longitude b_longitude,
	 			latitude b_latitude
		from	airports ap
	) as b on f.arrival_airport = b.b_code
	left join (
		select
				model || ' (' || aircraft_code || ')' aircraft_model,
				"range" aircraft_range,
				aircraft_code 
		from	aircrafts ad
	) as p on f.aircraft_code = p.aircraft_code
)
with no data;

refresh materialized view flights_distance;


---- 1.3. Compare distance with aircraft range:

select	
		fd.distance_km range_act,
		fd.aircraft_range range_plan,
		case 
			when (fd.aircraft_range > (fd.distance_km * 1.1)) then 'Within range'
			when (fd.aircraft_range >= fd.distance_km) then 'Borderline case'
			else 'Overused (longer than range)'
		end as range_usage,
		fd.aircraft_model,
		fd.departure_code departure,
		fd.arrival_code arrival,
		fd.route
from	flights_distance fd 
order by	range_usage;




-- Option 2 (no extra structures):

select	
		(1.609344 * (acos(sin(pi() * a_latitude / 180) * sin(pi() * b_latitude / 180) + cos(pi() * a_latitude / 180) * cos(pi() * b_latitude / 180) * cos(pi() * (a_longitude - b_longitude) / 180))) * 180 / pi() * 60 * 1.1515)::int as distance_km,
		p.aircraft_range,
		p.aircraft_model,
		a_code,
		b_code,
		a_city || ' - ' || b_city route
from (
	select
			departure_airport,
			arrival_airport,
			aircraft_code
	from	flights fl
	group by departure_airport, arrival_airport, aircraft_code 
) as f 
left join (
	select	airport_code a_code,
 			city || ' (' || airport_name || ', '|| airport_code || ')' a_city,
 			longitude a_longitude,
 			latitude a_latitude
	from	airports ap
) as a on f.departure_airport = a.a_code
left join (
	select	airport_code b_code,
 			city || ' (' || airport_name || ', '|| airport_code || ')' b_city,
 			longitude b_longitude,
 			latitude b_latitude
	from	airports ap
) as b on f.arrival_airport = b.b_code
left join (
	select
			model || ' (' || aircraft_code || ')' aircraft_model,
			"range" aircraft_range,
			aircraft_code 
	from	aircrafts ad
) as p on f.aircraft_code = p.aircraft_code
order by	distance_km desc;


--where a_code in ('SVO', 'TOF') and b_code in ('SVO', 'TOF')
--- Check: 2,898 km
-- select distance(56.3883, 85.2096, 55.9736, 37.4125)