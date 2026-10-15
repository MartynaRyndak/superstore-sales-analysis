-- Projekt analizy sprzedaży Sample Superstore
-- Analiza biznesowa
-- Silnik bazy danych: MySQL
-- Narzędzie: DBeaver

-- Wymaganie:
-- Przed uruchomieniem tego skryptu należy wykonać
-- 01_database_and_raw_tables.sql oraz
-- 02_data_preparation_and_quality.sql.


use sales_project;


--ANALIZA BIZNESOWA - Z POZIOMU SQL

--jaka jest łączna sprzedaż, łączny zysk i marża zysku?

select 
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk, 
	round(sum(profit)/sum(sales)*100, 2) as marza 
from orders;

--jak zmieniała się sprzedaż i zysk w czasie,
--czy firma się rozwija? Podział na lata:

select distinct year(order_date) as rok from orders order by rok asc;

select 
	year(order_date) as rok,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk, 
	round(sum(profit)/sum(sales)*100, 2) as marza 
from orders
group by rok
order by rok asc;


--sprzedaż i zysk a region?

select 
	region,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza
from orders  
group by  region;


select 
	o.region,
	p.person,
	round(sum(o.sales), 2) as sprzedaz,
	round(sum(o.profit), 2) as zysk,
	round(sum(o.profit)/sum(o.sales)*100, 2) as marza
from orders o   
join people p on
o.region=p.region
group by  o.region, p.person
order by sprzedaz desc;



--jakie mamy podkategorie?

select 
distinct category,
GROUP_CONCAT( distinct sub_category separator ', ') as sub_category
from orders
group by category;

--sprzedaż, zysk i marża dla każdej kategorii produktów

select 
	category,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza
from orders 
group by category
order by sprzedaz desc;


--które podkategorie sa nierentowne?

select 
	category,
	sub_category,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza
from orders 
group by category, sub_category
having sum(profit) <0
order by zysk asc;


--czy nierentowne podkategorie mają wysokie rabaty?

select 
	category,
	sub_category,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza,
	round(avg(discount)*100, 2) as discount
from orders 
group by category, sub_category
having sum(profit) <0
order by zysk asc;


--porównanie wszystkich kategorii
-- czy podkategorie z najwyższymi średnimi rabatami mają najniższe zyski i marże?

select 
	category,
	sub_category,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza,
	round(avg(discount)*100, 2) as discount
from orders 
group by category, sub_category
order by discount desc;


-- PIERWSZA PRÓBA:
-- Przypisanie całej podkategorii do przedziału na podstawie jej średniego rabatu.
-- To podejście pozwala porównać podkategorie, ale nie pokazuje wyników
-- wszystkich transakcji należących do poszczególnych przedziałów rabatowych.

select 
	category,
	sub_category,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza,
	case
		when avg(discount) = 0 then '0%'
		when avg(discount) <= 0.10 then '1-10%'
		when avg(discount) <= 0.20 then '11-20%'
		when avg(discount) <= 0.30 then '21-30%'
		else 'powyżej 30%'
	end as discount_band
from orders 
group by category, sub_category
order by avg(discount) desc;

-- ZMIANA PODEJŚCIA:
-- Najpierw przypisujemy każdą pozycję zamówienia do przedziału rabatowego,
-- a następnie obliczamy łączną sprzedaż, zysk i marżę dla przedziałów.

select
	case
		when discount = 0 then '0%'
		when discount <= 0.10 then '1-10%'
		when discount <= 0.20 then '11-20%'
		when discount <= 0.30 then '21-30%'
		else 'powyżej 30%'
	end as discount_band,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit) / sum(sales) * 100, 2) as marza
from orders
group by discount_band
order by min(discount);


-- POGŁĘBIENIE ANALIZY:
-- Sprawdzenie wpływu poszczególnych przedziałów rabatowych
-- na rentowność podkategorii Furniture.

select
category,
sub_category,
	case 
		when discount = 0  then '0%'
		when discount <= 0.10 then '1-10%'
		when discount <= 0.20 then '11–20%'
		when discount <= 0.30 then '21–30%'
		else 'powyżej 30%'
	end as discount_band,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza
from orders
where category = 'Furniture'
group by discount_band, category, sub_category
order by min(discount), category, sub_category;


--procent zwrotów dla kazdej kategorii

select 
	o.category,
	count(distinct o.order_id) as zamowienia,
	count(distinct r.order_id) as zwrot,
	round(count(distinct r.order_id)/count(distinct o.order_id)*100, 2) as procent_zwrot
from orders o left join returns r on 
o.order_id=r.order_id
group by o.category;


--10 produktów generujących największą łączną stratę

select 
	product_id,
	product_name,
	category,
	sub_category,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza
from orders
group by orders.product_id, product_name, category, sub_category
having sum(profit)<0
order by zysk asc
limit 10;


--zwroty wg regionu

select 
	o.region,
	p.person,
	count(distinct o.order_id) as zamowienia,
	count(distinct r.order_id) as zwroty,
	round(count(distinct r.order_id)/count(distinct o.order_id)*100, 2) as procent_zwrot
from orders o 
left join returns r on 
o.order_id=r.order_id
join people p on 
o.region=p.region
group by o.region, p.person
order by procent_zwrot desc;


--10 klientów generujących największą łączną sprzedaż

select 
	customer_id,
	customer_name,
	segment,
	count(distinct order_id) as ilosc_zam,
	round(sum(sales), 2) as sprzedaz,
	round(sum(profit), 2) as zysk,
	round(sum(profit)/sum(sales)*100, 2) as marza	
from orders
group by customer_id, customer_name, segment
order by  sprzedaz desc
limit 10;


-- czas realizacji zamówień według sposobu wysyłki
-- najpierw sprowadzamy dane do poziomu jednego zamówienia,
-- aby zamówienia wielopozycyjne nie zawyżały średniej

select
	ship_mode,
	count(order_id) as ilosc_zamowien,
	round(avg(datediff(ship_date, order_date)), 2) as sredni_czas,
	min(datediff(ship_date, order_date)) as minimalny_czas,
	max(datediff(ship_date, order_date)) as maksymalny_czas
from (
	select distinct
		order_id,
		order_date,
		ship_date,
		ship_mode
	from orders
) as unique_orders
group by ship_mode
order by sredni_czas;






