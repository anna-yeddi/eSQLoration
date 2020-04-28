--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2 (Debian 12.2-2.pgdg100+1)
-- Dumped by pg_dump version 12.2 (Debian 12.2-2.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.countries (
    country_id integer NOT NULL,
    country_name character varying(50) NOT NULL,
    region_id integer NOT NULL
);


ALTER TABLE public.countries OWNER TO postgres;

--
-- Name: countries_country_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.countries_country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.countries_country_id_seq OWNER TO postgres;

--
-- Name: countries_country_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.countries_country_id_seq OWNED BY public.countries.country_id;


--
-- Name: country_ethnicity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country_ethnicity (
    country_id integer NOT NULL,
    ethnicity_id integer NOT NULL
);


ALTER TABLE public.country_ethnicity OWNER TO postgres;

--
-- Name: country_language; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country_language (
    country_id integer NOT NULL,
    language_id integer NOT NULL
);


ALTER TABLE public.country_language OWNER TO postgres;

--
-- Name: ethnicities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ethnicities (
    ethnicity_id integer NOT NULL,
    ethnicity_name character varying(50) NOT NULL,
    language_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.ethnicities OWNER TO postgres;

--
-- Name: ethnicities_ethnicity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ethnicities_ethnicity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ethnicities_ethnicity_id_seq OWNER TO postgres;

--
-- Name: ethnicities_ethnicity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ethnicities_ethnicity_id_seq OWNED BY public.ethnicities.ethnicity_id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languages (
    language_id integer NOT NULL,
    language_name character varying(50) NOT NULL,
    primary_language_of integer
);


ALTER TABLE public.languages OWNER TO postgres;

--
-- Name: languages_language_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.languages_language_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.languages_language_id_seq OWNER TO postgres;

--
-- Name: languages_language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.languages_language_id_seq OWNED BY public.languages.language_id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.regions (
    region_id integer NOT NULL,
    region_name character varying(50) NOT NULL
);


ALTER TABLE public.regions OWNER TO postgres;

--
-- Name: regions_region_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.regions_region_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.regions_region_id_seq OWNER TO postgres;

--
-- Name: regions_region_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.regions_region_id_seq OWNED BY public.regions.region_id;


--
-- Name: countries country_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries ALTER COLUMN country_id SET DEFAULT nextval('public.countries_country_id_seq'::regclass);


--
-- Name: ethnicities ethnicity_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ethnicities ALTER COLUMN ethnicity_id SET DEFAULT nextval('public.ethnicities_ethnicity_id_seq'::regclass);


--
-- Name: languages language_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages ALTER COLUMN language_id SET DEFAULT nextval('public.languages_language_id_seq'::regclass);


--
-- Name: regions region_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regions ALTER COLUMN region_id SET DEFAULT nextval('public.regions_region_id_seq'::regclass);


--
-- Data for Name: countries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.countries (country_id, country_name, region_id) FROM stdin;
1	North	1
2	Mountain and the Vale	1
3	Isles and Rivers	1
4	Rock	1
5	Reach	1
6	Stormlands	1
7	Dorne	1
8	Beyond the Wall	1
9	Qarth	2
10	Lhazar	2
11	Rhoyne River	2
12	Free Cities	2
13	Slaver's Bay	2
\.


--
-- Data for Name: country_ethnicity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.country_ethnicity (country_id, ethnicity_id) FROM stdin;
1	1
1	3
1	2
2	2
3	2
4	2
5	2
6	2
7	1
7	2
7	6
8	1
8	3
8	4
8	5
9	9
10	8
11	6
11	2
11	23
12	10
12	11
12	12
12	13
12	14
12	15
12	16
12	17
12	18
13	2
13	22
13	19
13	20
13	21
\.


--
-- Data for Name: country_language; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.country_language (country_id, language_id) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
7	4
8	2
8	5
9	8
10	7
11	4
11	3
12	1
12	4
13	1
13	4
\.


--
-- Data for Name: ethnicities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ethnicities (ethnicity_id, ethnicity_name, language_id) FROM stdin;
1	First Men	2
2	Andals	1
3	Wildlings	2
4	Giants	2
5	White Walkers	5
6	Rhoynar	1
7	Dothraki	6
8	Lhazareen	7
9	Qartheen	8
10	Braavosi	4
11	Lorathi	4
12	Lysene	4
13	Pentoshi	4
14	Norvoshi	4
15	Qohorik	4
16	Volantene	4
17	Myrish	4
18	Tyroshi	4
19	Astapori	4
20	Yunkish	4
21	Meerenese	4
22	Ghiscari	4
23	Valyrian	3
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.languages (language_id, language_name, primary_language_of) FROM stdin;
1	Common Tongue	2
2	Old Tongue	1
3	High Valyrian	23
4	Low Valyrian	6
5	Skroth	5
6	Dothraki	7
7	Lhazar	8
8	Qarth	9
\.


--
-- Data for Name: regions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.regions (region_id, region_name) FROM stdin;
1	Westeros
2	Essos
\.


--
-- Name: countries_country_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.countries_country_id_seq', 13, true);


--
-- Name: ethnicities_ethnicity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ethnicities_ethnicity_id_seq', 23, true);


--
-- Name: languages_language_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.languages_language_id_seq', 8, true);


--
-- Name: regions_region_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.regions_region_id_seq', 2, true);


--
-- Name: countries countries_country_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_country_id_key UNIQUE (country_id);


--
-- Name: countries countries_country_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_country_name_key UNIQUE (country_name);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (country_id, region_id);


--
-- Name: country_ethnicity country_ethnicity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_ethnicity
    ADD CONSTRAINT country_ethnicity_pkey PRIMARY KEY (country_id, ethnicity_id);


--
-- Name: country_language country_language_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_language
    ADD CONSTRAINT country_language_pkey PRIMARY KEY (country_id, language_id);


--
-- Name: ethnicities ethnicities_ethnicity_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ethnicities
    ADD CONSTRAINT ethnicities_ethnicity_id_key UNIQUE (ethnicity_id);


--
-- Name: ethnicities ethnicities_ethnicity_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ethnicities
    ADD CONSTRAINT ethnicities_ethnicity_name_key UNIQUE (ethnicity_name);


--
-- Name: ethnicities ethnicities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ethnicities
    ADD CONSTRAINT ethnicities_pkey PRIMARY KEY (ethnicity_id, language_id);


--
-- Name: languages languages_language_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_language_name_key UNIQUE (language_name);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (language_id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (region_id);


--
-- Name: countries countries_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.regions(region_id);


--
-- Name: country_ethnicity country_ethnicity_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_ethnicity
    ADD CONSTRAINT country_ethnicity_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(country_id);


--
-- Name: country_ethnicity country_ethnicity_ethnicity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_ethnicity
    ADD CONSTRAINT country_ethnicity_ethnicity_id_fkey FOREIGN KEY (ethnicity_id) REFERENCES public.ethnicities(ethnicity_id);


--
-- Name: country_language country_language_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_language
    ADD CONSTRAINT country_language_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(country_id);


--
-- Name: country_language country_language_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_language
    ADD CONSTRAINT country_language_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(language_id);


--
-- Name: ethnicities ethnicities_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ethnicities
    ADD CONSTRAINT ethnicities_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(language_id);


--
-- PostgreSQL database dump complete
--

