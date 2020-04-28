-- Languages:

create table languages(
	language_id serial unique not null,
	language_name varchar(50) unique not null,
	spoken_by integer,
	primary key(language_id)
);

insert into languages(language_name)
	values ('Common Tongue'), ('Old Tongue'), ('High Valyrian'), ('Low Valyrian'),
			('Skroth'), ('Dothraki'), ('Lhazar'), ('Qarth');

		
		
-- Ethnicities:

create table ethnicities(
	ethnicity_id serial unique not null,
	ethnicity_name varchar(50) unique not null,
	language_id integer default 1,
	primary key(ethnicity_id, language_id),
	foreign key(language_id) references languages(language_id)
);

insert into ethnicities(ethnicity_name, language_id)
	values ('First Men', 2), ('Andals', 1), ('Wildlings', 2), ('Giants', 2),
			('White Walkers', 5), ('Rhoynar', 1), ('Dothraki', 6), ('Lhazareen', 7),
			('Qartheen', 8), ('Braavosi', 4), ('Lorathi', 4), ('Lysene', 4),
			('Pentoshi', 4), ('Norvoshi', 4), ('Qohorik', 4), ('Volantene', 4),
			('Myrish', 4), ('Tyroshi', 4), ('Astapori', 4), ('Yunkish', 4), ('Meerenese', 4), 
			('Ghiscari', 4), ('Valyrian', 3);

		
--- Add corresponding ethnicities:
		
alter table languages rename column spoken_by to primary_language_of;

update languages set primary_language_of = '2' where language_name like 'Common%';
update languages set primary_language_of = '1' where language_name like 'Old%';
update languages set primary_language_of = '23' where language_name like 'High%';
update languages set primary_language_of = '6' where language_name like 'Low%';
update languages set primary_language_of = '5' where language_name like 'Skroth';
update languages set primary_language_of = '7' where language_name like 'Dothraki';
update languages set primary_language_of = '8' where language_name like 'Lhazar';
update languages set primary_language_of = '9' where language_name like 'Qarth';

alter table languages
	drop constraint constraint_fk;




-- Countries:


--- Add regions:

create table regions(
	region_id serial primary key,
	region_name varchar(50) not null,
);

insert into regions(region_name) values ('Westeros'), ('Essos');



--- Add countries:

create table countries(
	country_id serial unique not null,
	country_name varchar(50) unique not null,
	region_id int references regions(region_id),
	primary key (country_id, region_id)
);

insert into countries(country_name, region_id)
	values ('North', 1), ('Mountain and the Vale', 1), ('Isles and Rivers', 1),
			('Rock', 1), ('Reach', 1), ('Stormlands', 1), ('Dorne', 1),
			('Beyond the Wall', 1), ('Qarth', 2), ('Lhazar', 2), ('Rhoyne River', 2),
			('Free Cities', 2), ('Slaver''s Bay', 2);



--- Add corresponding languages:

create table country_language (
	country_id int references countries(country_id),
	language_id int references languages(language_id),
	primary key (country_id, language_id)
);

insert into country_language(country_id, language_id) (
	values (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1),
			(7, 1), (7, 4), (8, 2), (8, 5), (9, 8), (10, 7),
			(11, 4), (11, 3), (12, 1), (12, 4), (13, 1), (13, 4)
);


--- Add corresponding ethnicities:

create table country_ethnicity (
	country_id int references countries(country_id),
	ethnicity_id int references ethnicities(ethnicity_id),
	primary key (country_id, ethnicity_id)
);

insert into country_ethnicity(country_id, ethnicity_id) (
	values (1, 1), (1, 3), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
			(6, 2), (7, 1), (7, 2), (7, 6), (8, 1), (8, 3), (8, 4),
			(8, 5), (9, 9), (10, 8), (11, 6), (11, 2), (11, 23),
			(12, 10), (12, 11), (12, 12), (12, 13), (12, 14),
			(12, 15), (12, 16), (12, 17), (12, 18), (13, 2),
			(13, 22), (13, 19), (13, 20), (13, 21)
);


select * from countries;
select * from regions;
select * from country_language;
select * from country_ethnicity;
select * from languages;
select * from ethnicities ;

select * from ethnicities e
	join languages using(language_id)
	order by ethnicity_name desc;

-- Information from the GOT Wiki: https://gameofthrones.fandom.com/
-- Docker container: https://hub.docker.com/repository/docker/m3ta007/postgres-got
