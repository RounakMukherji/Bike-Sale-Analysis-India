create table Bikes (
Brand varchar(15) not null,
Bike_Model varchar(20) primary key,
Engine_CC int not null,
Milage_kmpl decimal(4,2) not null,
Bike_Type text,
Price decimal(10,2) not null);

create table Customers (
Cust_ID varchar(10) primary key,
Age int not null check (Age>=18),
State varchar(20) not null,
City_Tier text,
Avg_Daily_Distance_Travells decimal(5,2),
Annual_Income_Range text);

create table Sales (
Sale_ID int primary key,
Cust_ID varchar(10),
Bikes varchar(20),
Sale_date date,
Resale_Price decimal(10,2),
Payment_Mode varchar(5) not null,
EMI_Duration_Months int,
Satisfaction int check(satisfaction between 1 and 10),
foreign key (Cust_ID) references customers(Cust_ID),
foreign key (bikes) references bikes(Bike_Model));

-- I have imported data from all the CSV files at the relevant tables.

-- 1. Revenue contribution by bike (Top 5 Revenue Maker)
With bike_revenue_CTE as (select b.Bike_Model,count(s.Sale_ID)*b.Price as total_revenue from sales s join bikes b on s.bikes=b.Bike_Model group by b.Bike_Model)
select Bike_Model, total_revenue from (select *, dense_rank() over(order by total_revenue desc) as rnk from bike_revenue_CTE) t where rnk<=5;

-- 2. Revenue share percentage of each segment.
with bike_revenue_CTE as (select b.Bike_Type, count(s.Sale_ID)*avg(b.Price) as total_revenue from sales s join bikes b on s.Bikes=b.Bike_Model group by b.Bike_Type)
select Bike_Type, round(total_revenue*100/sum(total_revenue) over(),2) as share_percenatge from bike_revenue_CTE order by share_percenatge desc;

-- 3. Top 5 highest rated bikes in indian market
with ranking as ( select bikes, round(avg(Satisfaction),1) as customer_ratings, dense_rank() over(order by avg(Satisfaction) desc) as rnk from sales group by bikes)
select bikes,customer_ratings from ranking where rnk<=5 order by customer_ratings desc;

-- 4. Top 5 most popular bikes and engine power in indian market
with CTE1 as (select b.Bike_Model, b.engine_CC, count(s.sale_ID) as purchase_count from sales s join bikes b on s.Bikes=b.Bike_Model group by b.Bike_Model, b.engine_CC),
CTE2 as (select *, dense_rank() over(order by purchase_count desc) as Ranking_as_Popularity from CTE1)
select Ranking_as_Popularity,Bike_Model,engine_CC from CTE2 where Ranking_as_Popularity<=5;

-- 5. Target customer's annual income for each segment
With CTE as (select c.Annual_Income_Range as Target_Annual_Income_Range, b.Bike_Type as Segment, count(s.sale_ID) as Order_Quantity from sales s join customers c on s.Cust_ID=c.Cust_ID join bikes b on s.Bikes=b.Bike_Model group by c.Annual_Income_Range, b.Bike_Type),
ranked as (select *,dense_rank() over(partition by Segment order by Target_Annual_Income_Range desc) as rnk from CTE)
select Segment,Target_Annual_Income_Range, Order_Quantity from ranked where rnk=1 order by Order_Quantity desc;

-- 6. Target age group by each segment
with CTE1 as (select case when c.age<25 then 'Under 25' when c.age between 25 and 40 then 'Middle Age' when c.age between 41 and 60 then 'Late Middle Age' else '60+' end as age_group, b.Bike_Type, count(s.Sale_ID) as purchase from customers c join sales s on c.Cust_ID=s.Cust_ID join bikes b on s.Bikes=b.Bike_Model group by age_group, b.Bike_Type),
CTE2 as (select *, dense_rank() over (partition by Bike_Type order by purchase desc) as rnk from CTE1)
select bike_type, age_group from CTE2 where rnk=1;

-- 7. Average milage and weighted average price of each segment
select b.Bike_Type as segment, round(avg(b.Milage_kmpl),2) as average_milage, round(sum(b.price*1)/count(s.sale_ID),2) as weighted_average_price from sales s join bikes b on s.Bikes=b.Bike_Model group by Bike_Type order by weighted_average_price desc; 

-- 8. Bikes with best resale value
select bikes,round(avg(Resale_Price),2) as resale_value from sales group by bikes order by resale_value desc;

-- 9. Depreciation Analysis by bike models
select s.bikes, b.price, round(avg(s.resale_price),2) as resale_value, round(avg(b.price-s.resale_price)*100/b.price,2) as depreciation_rate from sales s join bikes b on s.Bikes=b.Bike_Model group by s.bikes, b.price;

-- 10. State wise cruiser bike demand and purchase percentage
with CTE1 as (select c.state, count(s.Sale_ID) as purchase_count from customers c join sales s on c.Cust_ID=s.Cust_ID join bikes b on s.Bikes=b.Bike_Model where b.Bike_Type='Cruiser' group by c.state, b.Bike_Type),
CTE2 as (select *, round(purchase_count*100/sum(purchase_count) over(),2) as purchase_percenatge from CTE1)
select state,purchase_count,purchase_percenatge from CTE2 order by purchase_count desc;