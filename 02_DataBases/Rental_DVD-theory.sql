select film_id as FilmID,
	title as FilmTitle,
	description as FilmDescription,
	release_year as FilmReleaseYear,
	rental_rate / rental_duration as FilmRentalDaily
	from film f 
	order by filmrentaldaily desc ;
	
select distinct release_year from film f ;

select title,
	rating from film f 
	where rating = 'PG-13';