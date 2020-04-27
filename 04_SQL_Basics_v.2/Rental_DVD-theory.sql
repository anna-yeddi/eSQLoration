-- 1. Create a table:

drop table if exists author restrict;

create table author(
	id serial primary key,
	full_name varchar(255) not null,
	alias varchar(50),
	dob date not null
);


-- 2. Alter the table:

-- October 8, 1892, Moscow, Russia
-- September 21, 1947, Portland, ME, US
-- June 6, 1799, Moscow, Russia
-- May 15, 1891, Kyiv, Russian Empire
insert into author (full_name, dob) 
values ('Marina King', '1891-05-15'),
	('Stephen Bulgakov','1799-06-06'),
	('Alexander Tsvetaeva', '1947-09-21'),
	('Mikhail Pushkin', '1892-10-08');

alter table author add column pob varchar(50);

update author 
	set pob = 'Moscow, Russia'
	where full_name similar to '(Mikhail|Stephen)%'
		and pob is null;

update author 
	set pob = 'Kyiv, Russian Empire'
	where full_name not like 'Marina%'
		and pob is null;

update author 
	set pob = 'Portland, ME, US'
	where full_name like '%King'
		and pob is null;
	
	
-- 3. Create a foreign key:

create table works(
	year_pub date,
	title varchar(255) unique not null,
	author_id integer,
	primary key(title, author_id),
	foreign key(author_id) references public.author(id)
);
	
insert into works(title, author_id)
	values ('Master and Lyudmila', 5),
			('Ruslan and Spirit', 4),
			('A Captive Dome', 2),
			('Under the Margarita', 3),
			('Pet of a Dog', 3),
			('Heart of Onegin', 5);

delete from author 
	where id = 3;
		

-- 4. Sum of orders (JSON):

create table orders(
	id serial not null primary key,
	info json not null
);

insert into orders(info)
	values
	(
		'{"customer": "Jane Doe", "items": {"product": "Vanilla Ice Cream", "qty": 6}}'
	),
	(
		'{"customer": "Roger One", "items": {"product": "Waffle Cones", "qty": 24}}'
	),
	(
		'{"customer": "Rogue Kenobi", "items": {"product": "Chocolate Ice Cream, 3 Scoops", "qty": 1}}'
	),
	(
		'{"customer": "Obi Yoda", "items": {"product": "Vanilla Ice Cream", "qty": 2}}'
	);

select info -> 'items' ->> 'product' as product,
	info -> 'items' ->> 'qty' as qty
	from orders
	where (info -> 'items' ->> 'qty')::integer = 6;

select sum(cast(info -> 'items' ->> 'qty' as integer)) as qty_total
	from orders;


-- 5. Count special features:

select film_id, title, special_features,
	array_length(special_features, 1) as num_of_special_features
	from film
	order by num_of_special_features desc;
	

select film_id, title, special_features,
	cardinality(special_features) as num_of_special_features
	from film
	order by num_of_special_features desc;