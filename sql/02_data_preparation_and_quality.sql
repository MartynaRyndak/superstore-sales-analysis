-- Projekt analizy sprzedaży Sample Superstore
-- Przygotowanie i kontrola jakości danych
-- Silnik bazy danych: MySQL
-- Narzędzie: DBeaver

use sales_project;

-- Ten skrypt należy uruchomić po zaimportowaniu danych
-- do tabel raw_orders, raw_returns oraz raw_people.

-- Kolejne zapytania były wykonywane podczas eksploracyjnej kontroli importu.
-- Pozostawiono je, aby pokazać przebieg weryfikacji danych.

select * from raw_orders limit 10;

select count(*) from raw_orders;

select * from raw_returns limit 10;

select * from raw_people;

SELECT COUNT(*) AS orders_rows FROM raw_orders;

SELECT COUNT(*) AS returns_rows FROM raw_returns;

SELECT *
FROM raw_orders
LIMIT 10;

SELECT 
    raw_order_date,
    raw_ship_date,
    raw_sales,
    quantity,
    raw_discount,
    raw_profit
FROM raw_orders
LIMIT 20;

-- CZYSZCZENIE I KONWERSJA TYPÓW
-- Daty oraz wartości sprzedaży, rabatu i zysku zostały zaimportowane
-- jako tekst i wymagają sprawdzenia oraz konwersji. 

--TEST KONWERSJI

--czy wszystkie daty da sie prawidłowo zamienić z tekstu na typ DATE?
select 
	raw_order_date, STR_TO_DATE(raw_order_date, '%d.%m.%Y') as order_date,
	raw_ship_date, STR_TO_DATE(raw_ship_date, '%d.%m.%Y') as ship_date
from raw_orders 
limit 10;

--czy we wszystkich 9994 wierszach daty mozna przekonwertować?
select count(*) as incorrect_dates 
from raw_orders 
where STR_TO_DATE(raw_order_date, '%d.%m.%Y') is null 
or STR_TO_DATE(raw_ship_date, '%d.%m.%Y') is null; 


--czy te trzy kolumny da sie przekonwertowac?

--po sprawdzeniu sales traci dokładność, potrzebujemy minimum 4 miejsca po przecinku, zamiast 2
select 
	raw_sales,
	CAST(replace(raw_sales, ',','.') as decimal(12,4)) as sales,
	
	raw_discount, 
	cast(replace(raw_discount, ',','.') as decimal(5,4)) as discount,
	
	raw_profit,
	cast(replace(raw_profit, ',','.') as decimal(12,4)) as profit
from raw_orders
limit 10;

--czy w kolumnach nie ma null albo pustego tekstu?
select 
	sum(raw_sales is null or trim(raw_sales) = '') as missing_sales,
	sum(raw_discount is null or trim(raw_discount) = '') as missing_discount,
	sum(raw_profit is null or trim(raw_profit) = '') as missing_profit 
from raw_orders;

--czy format liczb jest poprawny? (spr niepustych i błędnych) 
select 
	SUM(TRIM(raw_sales) not regexp '^-?[0-9]+([,.][0-9]+)?$') 
		as incorrect_sales,
	
	SUM(TRIM(raw_discount) not regexp '^-?[0-9]+([,.][0-9]+)?$')
		as incorrect_discount,
		
	SUM(TRIM(raw_profit) not regexp '^-?[0-9]+([,.][0-9]+)?$')
		as incorrect_profit
	from raw_orders;
	

--czy row_id może być kluczem? (unikalnośc? not null?)
select 
	count(*) as all_rows,
	count(row_id) as rows_with_id,
	count(distinct row_id) as unique_ids
from raw_orders;	


--TWORZENIE TABEL DLA CZYSTYCH DANYCH

--ORDERS

CREATE TABLE orders (
    row_id INT primary key,
    order_id VARCHAR(20) not null,
    order_date DATE not null,
    ship_date DATE not null,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales DECIMAL(12,4),
    quantity INT,
    discount DECIMAL(5,4),
    profit DECIMAL(12,4)
);


--wstawimy dane z raw_orders do orders, wykonując po drodze konwersje
INSERT INTO orders (
row_id,
order_id,
order_date,
ship_date,
ship_mode,
customer_id,
customer_name,
segment,
country,
city,
state,
postal_code,
region,
product_id,
category,
sub_category,
product_name,
sales,
quantity,
discount,
profit
)
SELECT
row_id,
TRIM(order_id),
STR_TO_DATE(raw_order_date, '%d.%m.%Y'),
STR_TO_DATE(raw_ship_date, '%d.%m.%Y'),
TRIM(ship_mode),
TRIM(customer_id),
TRIM(customer_name),
TRIM(segment),
TRIM(country),
TRIM(city),
TRIM(state),
TRIM(postal_code),
TRIM(region),
TRIM(product_id),
TRIM(category),
TRIM(sub_category),
TRIM(product_name),
CAST(REPLACE(raw_sales, ',', '.') AS DECIMAL(12,4)),
quantity,
CAST(REPLACE(raw_discount, ',', '.') AS DECIMAL(5,4)),
CAST(REPLACE(raw_profit, ',', '.') AS DECIMAL(12,4))
FROM raw_orders;


--testy:

--czy ilczba rekordów się zgadza?
select 
	(select count(*) from raw_orders) as raw_rows,
	(select count(*) from orders) as clean_rows;


--czy typy danych sie zgadzają?
describe orders;

--czy logika dat się zgadza? (czy nie ma zamówienia wysłanego przed jego załozeniem)
select count(*) as incorrect_shipping_dates
from orders 
where ship_date < order_date ;

--czy zakresy wartości liczbowych są w porządku?
select 
	SUM(sales < 0) as negative_sales,
	SUM(quantity <= 0) as incorrect_quantity,
	SUM(discount < 0 or discount > 1) as incorrect_discount
from orders;	


-- czy order_id może być kluczem głównym tabeli returns?
select
	count(*) as all_rows,
	count(order_id) as rows_with_order_id,
	count(distinct order_id) as unique_order_ids,
	count(distinct raw_returned) as returned_values
from raw_returns;


--jakie wartości mamy w raw_returns?
select distinct raw_returned
from raw_returns;


--czy wszystkie rekordy sa połączone z tabelą orders?
select 
count(order_id) as returns_with_order
from raw_returns 
where order_id in 
(select order_id from orders);


-- ile rekordów z raw_returns nie ma odpowiadającego zamówienia w orders?
-- oczekiwany wynik: 0
select count(*) as unmatched_returns
from raw_returns r
where not exists (
	select 1
	from orders o
	where o.order_id = trim(r.order_id)
);



--RETURNS

--tworzymy nową tabele returns:
create table returns(	
	order_id VARCHAR(20) primary key,
	returned boolean not null
);


describe returns;

insert into returns (
	order_id,
	returned
)
select 
	trim(order_id),
	true
from raw_returns;


-- TESTY 

SELECT
    returned,
    COUNT(*) AS number_of_orders
FROM returns
GROUP BY returned;


select 
	count(*) as all_people_rows,
	count(region) as people_rows_with_region,
	count(person) as people_rows_with_person,
	count(distinct region) as unique_people_regions
from raw_people;


select 
	count(region) as region_zz
	from raw_people
	where region in(
select region 
from orders
);


-- które regiony z raw_people nie występują w orders?
-- zapytanie nie powinno zwrócić żadnego wiersza
select distinct trim(rp.region) as unmatched_region
from raw_people rp
left join (
	select distinct region
	from orders
) as o
	on trim(rp.region) = o.region
where o.region is null;



--PEOPLE

create table people (
	region VARCHAR(50) primary key,
	person VARCHAR(100) not null
	
);

describe people;


insert into people (
	region,
	person	
)
select
	trim(region),
	trim(person)	
from raw_people;


select * from people;

select 
	(select count(*) from orders) as orders_rows,
	(select count(*) from returns) as returns_rows,
	(select count(*) from people) as people_rows;


-- ile mamy pozycji zamówień, unikalnych zamówień
-- oraz dodatkowych wierszy wynikających z wielopozycyjnych zamówień?

select 
	count(*) as order_lines,
	count(distinct order_id) as unique_orders,
	count(*) - count(distinct order_id) as additional_order_lines
from orders;




-- czy wszystkie pozycje jednego zamówienia mają spójne dane?
-- zapytanie nie powinno zwrócić żadnego wiersza
select
	order_id,
	count(distinct customer_id) as customers,
	count(distinct order_date) as order_dates,
	count(distinct ship_date) as ship_dates,
	count(distinct ship_mode) as ship_modes,
	count(distinct region) as regions
from orders
group by order_id
having count(distinct customer_id) > 1
	or count(distinct order_date) > 1
	or count(distinct ship_date) > 1
	or count(distinct ship_mode) > 1
	or count(distinct region) > 1;


-- liczba wierszy i unikalnych zamówień w tabeli returns
select
	count(order_id) as return_rows,
	count(distinct order_id) as unique_returned_orders
from returns;


-- liczba zwróconych zamówień oraz liczba pozycji produktowych
-- należących do zwróconych zamówień
select
	count(distinct r.order_id) as returned_orders,
	count(o.order_id) as returned_order_lines
from returns r
left join orders o
	on r.order_id = o.order_id;


--połączenie orders-people
select count(region) from orders
where region in(select region from people);


-- ile rekordów z orders ma region bez dopasowania w people?
-- oczekiwany wynik: 0
select count(*) as orders_without_person
from orders o
left join people p
	on o.region = p.region
where p.region is null;


-- POZIOM SZCZEGÓŁOWOŚCI DANYCH:
-- orders: jedna pozycja produktowa zamówienia,
-- returns: jedno zwrócone zamówienie,
-- people: jedna osoba odpowiedzialna za region.
-- Z tego powodu przy liczeniu zamówień stosujemy count(distinct order_id).


