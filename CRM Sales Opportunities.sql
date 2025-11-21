Project Brief: Sales Performance Analysis

Analyze the performance of a sales team's ability to win deals and earn revenue

CRM Sales Opportunities
B2B sales pipeline data from a fictitious company that sells computer hardware

File Type: CSV
Data Structure: Multiple Tables
# of Records: 8800
# of Fields: 18

use crm_sales;


select * from accounts
select * from products
select * from sales_pipeline
select * from sales_teams


Objective 1
Pipeline metrics
Your first objective is to assess the overall sales pipeline by looking at opportunities by month, time to close, win rate, and product data

Task

Calculate the number of sales opportunities created each month using "engage_date", and identify the month with the most opportunities

select year(engage_date) as yr, monthname(engage_date) as mnth, count(*) as num_oppor
from sales_pipeline
group by yr, mnth
order by 3 desc
limit

or 

with cte as
(
select year(engage_date) as yr, monthname(engage_date) as mnth, count(*) as num_oppor,
       rank() over(order by count(*) desc) as most_oppor
from sales_pipeline
group by yr, mnth
order by 3 desc
)
select * from cte
where most_oppor = 1

or

select yr, mnth, num_oppor 
from
(
select year(engage_date) as yr, monthname(engage_date) as mnth, count(*) as num_oppor,
       rank() over(order by count(*) desc) as most_oppor
from sales_pipeline
group by yr, mnth
order by 3 desc
) x
where most_oppor = 1

Find the average time deals stayed open (from "engage_date" to "close_date"), and compare closed deals versus won deals

select 'overall_average' as deal_stage, round(avg(datediff(close_date, engage_date)),0) as avg_time_days from sales_pipeline
union all
select deal_stage, round(avg(datediff(close_date, engage_date)),0) as avg_time_days from sales_pipeline group by deal_stage

Calculate the percentage of deals in each stage, and determine what share were lost

select deal_stage, count(*) as num_oppor,
      round(count(*)*100/(select count(*) from sales_pipeline),2) as percentage
      from sales_pipeline
group by deal_stage

or

select avg(case when deal_stage = 'Lost' then 1 else 0 end)*100 as loss_rate 
from sales_pipeline

Compute the win rate for each product, and identify which one had the highest win rate

select product,
       round(avg(case when deal_stage = 'Won' then 1 else 0 end)*100,2) as win_rate 
from sales_pipeline
group by product
order by win_rate desc


Objective 2
Sales agent performance
Your second objective is to assess the performance of sales agents, their managers, and regional offices

Task

Calculate the win rate for each sales agent, and find the top performer

select st.sales_agent,
       round(avg(case when deal_stage = 'Won' then 1 else 0 end)*100,2) as win_rate,
       rank() over(order by round(avg(case when deal_stage = 'Won' then 1 else 0 end)*100,2) desc) as top_performer
from
sales_teams st join sales_pipeline sp on st.sales_agent = sp.sales_agent
group by sales_agent

Calculate the total revenue by agent, and see who generated the most

select * from
(
select sales_agent, round(sum(close_value),2) as total_rev,
       rank() over(order by round(sum(close_value),2) desc) as rnk
from sales_pipeline
group by sales_agent
)x
where x.rnk=1

Calculate win rates by manager to determine which manager’s team performed best

select manager,  
       avg(case when deal_stage = 'Won' then 1 else 0 end)*100 as win_rate,
       dense_rank() over(order by avg(case when deal_stage = 'Won' then 1 else 0 end)*100 desc) as rnk
from sales_teams sa
join sales_pipeline sp on sa.sales_agent = sp.sales_agent
group by manager
limit 1

For the product GTX Plus Pro, find which regional office sold the most units

select regional_office, count(*) as sold_units
from sales_teams sa
join sales_pipeline sp on sa.sales_agent = sp.sales_agent
where deal_stage = 'Won' and product = 'GTX Plus Pro'
group by regional_office
order by sold_units desc

Objective 3
Product analysis
Your third objective is to analyze the sales performance and quantity sold of the company's product portfolio
Task

For March deals, identify the top product by revenue and compare it to the top by units sold

select product, sum(close_value) as revenue, count(*) as units_sold
from sales_pipeline
where monthname(close_date) = 'March' and deal_stage = 'Won'
group by product

Calculate the average difference between "sales_price" and "close_value" for each product, and note if the results suggest a data issue

select sp.product as product,
       avg(sales_price - close_value) as avg_diff
from sales_pipeline sp join products p on sp.product = p.product
where deal_stage = 'Won'
group by product
order by 2 desc

Calculate total revenue by product series and compare their performance

select p.series as prod_series , sum(close_value) as total_revenue
from sales_pipeline sp join products p on p.product = sp.product
where deal_stage = 'Won'
group by prod_series
order by 2 desc

Objective 4
Account analysis
Your final objective is to analyze the company's accounts to get a better understanding of the team's customers
Task

Calculate revenue by office location, and identify the lowest performer

select office_location, sum(revenue) as revenue
from accounts
group by office_location
order by revenue
limit 1

Find the gap in years between the oldest and newest customer, and name those companies

select account as company_name, year_established
from accounts
where year_established in ((select min(year_established) from accounts), (select max(year_established) from accounts))


Which accounts that were subsidiaries had the most lost sales opportunities?

select * from
(
select a.account as accounts, count(sp.opportunity_id) as opportunities,
       rank() over(order by count(sp.opportunity_id) desc) as rnk
from accounts a left join sales_pipeline sp
on a.account = sp.account
where subsidiary_of != '' and deal_stage = 'Lost'
group by accounts
) x
where x.rnk = 1

Join the companies to their subsidiaries. Which one had the highest total revenue?

with parent_company as
(
select account,
	   case when subsidiary_of = '' then account else subsidiary_of end as parent_company
from accounts
),
won_deals as
(
select account, close_value
from sales_pipeline
where deal_stage = 'Won'
)
select parent_company, sum(close_value) as revenue
from parent_company pc join won_deals wd
on pc.account = wd.account
group by parent_company
having sum(close_value)>10000
order by 2 desc
limit 1
