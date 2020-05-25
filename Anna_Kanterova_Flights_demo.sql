SET search_path = bookings;


-- В каких городах больше одного аэропорта?

--- Cloud DB (with JSONs):
select 
	count(city) num_of_airports,
	city ->> 'en' city_name
from airports_data ap
group by city
having count(city) > 1;


--- Local DB:

select 
	count(city) num_of_airports,
	city city_name
from airports ap
group by city
having count(city) > 1;





-- В каких аэропортах есть рейсы, которые обслуживаются самолетами с максимальной дальностью перелетов?


--- Cloud DB (with JSONs):
---  В данной БД создание индекса не сработает, т.к. недостаточно прав, но могло бы ускорить несколько запросов.
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




---- Drafts:
--- Airport name:
select	ad.airport_code,
		ad.airport_name ->> 'en' airport_name
from	airports_data ad ;

--- Flights:
select	f.departure_airport,
		f.arrival_airport,
		f.aircraft_code 
from	flights f ;

--- Max aircraft range:
select	acd.aircraft_code,
		acd.model ->> 'en' aircraft_model,
		acd."range" aircraft_range
from	aircrafts_data acd 
where	acd."range" = (
	select	max(acd."range")
	from	aircrafts_data acd 
);

--- Longer solution:
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






-- Были ли брони, по которым не совершались перелеты?
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



--- Drafts:

select	b.book_ref,
		t.ticket_no
from 	bookings b
left join	tickets t using (book_ref)
where	ticket_no is null;

select	count(distinct book_ref)
from	bookings b 



-- Самолеты каких моделей совершают наибольший % перелетов?
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

explain analyze

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



explain analyze

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



explain analyze
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





-- Были ли города, в которые можно  добраться бизнес-классом дешевле, чем эконом-классом?
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

--- 19.1 sec:
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


--- 16.7 sec:
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







-- Узнать максимальное время задержки вылетов самолетов
--- 4ч 37мин

select	max(actual_departure - scheduled_departure) as max_delay
from	flights f 
where	actual_departure is not null;

--- Top 10 delays:

select	actual_departure - scheduled_departure as delay,
		flight_no,
		departure_airport,
		arrival_airport 
from	flights f 
where		actual_departure is not null
order by	delay desc
limit		10;



---- Draft:

select	scheduled_departure,
		actual_departure,
		(actual_departure - scheduled_departure) as delay
from 	flights f 
where 	actual_departure is not null;






-- Между какими городами нет прямых рейсов*?


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
-- and df.departure_city = 'Томск'
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





--- List of connected cities:
with cte as (
	select	airport_code code,
			city
	from	airports a
)
select	cte1.city city1,
		cte2.city city2
from	flights f 
left join 	cte as cte1 on cte1.code = f.departure_airport 
left join 	cte as cte2 on cte2.code = f.arrival_airport 
group by	city1, city2











-- Между какими городами пассажиры делали пересадки*?

create index on flights(flight_id);

explain analyze

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
			and		(
						select	DATE_PART('day', c2.scheduled_departure - c1.scheduled_arrival) * 24 + 
		    					DATE_PART('hour', c2.scheduled_departure - c1.scheduled_arrival)
					) < 24
	) as layovers
	group by	departure_airport,
				arrival_airport 
) as l
left join	airports a1 on	l.departure_airport = a1.airport_code
left join	airports a2 on	l.arrival_airport = a2.airport_code;







---- Drafts:

select
	*
from airports ap

select
	*
from aircrafts ad 

select
	*
from flights f 
	
select
	*
from ticket_flights tf 

select
	*
from tickets t 

select
	*
from boarding_passes bp 

select
	*
from seats s

select
	*
from bookings b 


--- Full layover table:

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
		
		


with cte_flights as (
	select	f.flight_id,
			f.departure_airport,
			f.arrival_airport,
			f.scheduled_departure,
			f.scheduled_arrival 
	from	flights f
),
cte_tickets as (
	select	ticket_no,
			flight_id
	from	(
		select	ticket_no,
				count(ticket_no) over (partition by ticket_no) as num_flights,
				flight_id
		from	ticket_flights tf
	) as tf
	where	 num_flights >= 2
),
cte as (
	select	*
	from	cte_tickets
	left join 	cte_flights using(flight_id)
)
select	ticket_no,
		c1.departure_airport,
		c1.arrival_airport,
		c1.scheduled_departure,
		c1.scheduled_arrival,
		c2.departure_airport,
		c2.arrival_airport,
		c2.scheduled_departure,
		c2.scheduled_arrival
from	cte as c1
left join 	cte as c2 using(ticket_no)

where 	ticket_no = '0005432002040'



with cte as (
	select	ticket_no,
			f.departure_airport,
			f.arrival_airport,
			f.scheduled_departure,
			f.scheduled_arrival 
	from	(
		select	ticket_no,
				flight_id
		from	ticket_flights tf
		where 	ticket_no in (
			select	ticket_no 
			from	ticket_flights tf
			group by 	ticket_no
			having 		count(ticket_no) >= 2 
		)
	) as ti
	left join 	flights f using(flight_id)
)
select	departure_airport,
		arrival_airport
from	cte
where	departure_airport = (
	select	ticket_no
	from	cte
	group by 	ticket_no
	having 		min(scheduled_departure) = scheduled_departure
)


where 	ticket_no = '0005432002040'




-- Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы **

--- Кратчайшее расстояние между двумя точками A и B на земной поверхности (если принять ее за сферу) определяется зависимостью:
---- d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}, где latitude_a и latitude_b — широты, longitude_a, longitude_b — долготы данных пунктов, d — расстояние между пунктами, измеряемое в радианах длиной дуги большого круга земного шара.
--- Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
---- L = d·R, где R = 6371 км — средний радиус земного шара.
--- Для расчета расстояния между пунктами, расположенными в разных полушариях (северное-южное, восточное-западное) , знаки (±) у соответствующих параметров (широты или долготы) должны быть разными. 




-- Option 1
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

---- where fd.departure_code in ('SVO', 'TOF') and fd.arrival_code in ('SVO', 'TOF')



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





---- Drafts:



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

select	
		distance(a_latitude, a_longitude, b_latitude, b_longitude) as distance_km,
		p.aircraft_range,
		p.aircraft_model,
		a_code,
		b_code,
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
where a_code in ('SVO', 'TOF') and b_code in ('SVO', 'TOF')
order by	distance_km desc;


--- Check: 2,898 km
-- select distance(56.3883, 85.2096, 55.9736, 37.4125)


select	a_code,
		a_city,
		a_longitude,
		a_latitude,
		b_code,
		b_city,
		b_longitude,
		b_latitude,
		(6371*(acos(sin(a_latitude)*sin(b_latitude) + cos(a_latitude)*cos(b_latitude)*cos(a_longitude - b_longitude))))::int as distance_km
from (
	select
		departure_airport,
		arrival_airport,
		aircraft_code
	from flights fl
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
where a_code = 'SVO' and b_code = 'TOF'



select
	a.city || ' (' || f.departure_airport || ')' as airport_a,
	b.city || ' (' || f.arrival_airport || ')' as airport_b,
	6371*(acos(sin(a.latitude)*sin(b.latitude)+cos(a.latitude)*cos(b.latitude)*cos(a.longitude-b.longitude)))::int as distance_km,
	ac.model aircraft_model,
	ac."range" aircraft_range
from airports a
join (
	select
		departure_airport,
		arrival_airport,
		aircraft_code
	from flights fl
	group by departure_airport, arrival_airport, aircraft_code 
) as f on a.airport_code = f.departure_airport
left join airports b on b.airport_code = f.arrival_airport
left join aircrafts ac using(aircraft_code)
where f.departure_airport = 'SVO'