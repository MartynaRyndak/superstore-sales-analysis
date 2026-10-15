-- Projekt analizy sprzedaży Sample Superstore
-- Przygotowanie bazy i tabel surowych
-- Silnik bazy danych: MySQL
-- Narzędzie: DBeaver
--
-- Skrypt tworzy bazę danych oraz tabele przeznaczone
-- do importu surowych danych z plików CSV.

-- UTWORZENIE BAZY DANYCH

create database sales_project;

use sales_project;

-- UTWORZENIE TABEL SUROWYCH

CREATE TABLE raw_orders (
    row_id INT,
    order_id VARCHAR(20),
    raw_order_date VARCHAR(20),
    raw_ship_date VARCHAR(20),
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
    raw_sales VARCHAR(20),
    quantity INT,
    raw_discount VARCHAR(20),
    raw_profit VARCHAR(20)
);

--test, czy mamy tabele raw_orders?
select *
from raw_orders;

CREATE TABLE raw_returns (
    raw_returned VARCHAR(10),
    order_id VARCHAR(20)
);

--test, czy mamy tabele raw_returns?
select * 
from raw_returns;

CREATE TABLE raw_people (
    person VARCHAR(100),
    region VARCHAR(50)
);

--test, czy mamy tabele raw_people?
select * 
from raw_people;


-- IMPORT DANYCH
-- Plik źródłowy Sample - Superstore.xls zawiera trzy arkusze:
-- Orders, Returns oraz People.
-- Każdy arkusz zapisałam jako osobny plik CSV i zaimportowałam
-- do odpowiedniej tabeli raw za pomocą kreatora importu DBeaver.
-- Oczekiwana liczba rekordów:
-- raw_orders: 9994
-- raw_returns: 296
-- raw_people: 4


-- NASTĘPNY KROK:
-- Po wykonaniu tego skryptu należy zaimportować trzy pliki CSV
-- do tabel raw_orders, raw_returns oraz raw_people.
-- Po zakończeniu importu można uruchomić plik
-- 02_data_preparation_and_quality.sql.