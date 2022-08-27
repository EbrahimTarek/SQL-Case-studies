# Create tables
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

select * from members
select * from sales
select * from menu

--2.What is the total amount each customer spent at the restaurant?
	select customer_id , SUM(price)
	from sales S , menu m
	where S.product_id = M.product_id
	group by customer_id

--3.How many days has each customer visited the restaurant?
	select customer_id , COUNT (distinct order_date) as number_of_visits
	from sales
	group by customer_id

--4.What was the first item from the menu purchased by each customer?
	select customer_id , product_name
	from (select *,ROW_NUMBER() over (partition by customer_id order by order_date) as rownum from sales) f , menu m
	where f.product_id = m.product_id
	and rownum = 1

--5.What is the most purchased item on the menu and how many times was it purchased by all customers?
	select top 1 * from
	(
		select product_name ,COUNT(S.product_id) as total_purchase
		from sales S , menu m
		where S.product_id =m.product_id
		group by product_name
	)f
	order by total_purchase desc
	
--6.Which item was the most popular for each customer?
	with cte as
	(
	select * ,dense_rank() over (partition by customer_id order by count_of_products desc) as ranking
	from(
	select customer_id,product_name,COUNT(s.product_id)as count_of_products
	from sales S , menu m
	where S.product_id = m.product_id
	group by customer_id ,product_name
	)f
	)
	select customer_id , product_name 
	from cte
	where ranking = 1

--7.Which item was purchased first by the customer after they became a member?
	select customer_id , product_name , order_date , join_date
	from(
		select s.customer_id , product_name , ROW_NUMBER() over (partition by s.customer_id order by order_date) rownum , order_date ,join_date
		from sales s , members m , menu e
		where s.customer_id = m.customer_id
		and e.product_id = s.product_id
		and order_date >= join_date
		)f
	where rownum = 1

--8.Which item was purchased just before the customer became a member? 
	select customer_id , product_name , ranking
	from
	(
	select s.customer_id , product_id ,order_date , ROW_NUMBER() over (partition by s.customer_id order by order_date desc) ranking
	from sales s , members m
	where order_date < join_date
	)f , menu m
	where f.product_id = m.product_id
	and ranking = 1

--9.What is the total items and amount spent for each member before they became a member?
	select s.customer_id , COUNT(s.product_id) as total_products, SUM(price) as total_price
	from members m , sales s , menu e
	where m.customer_id = s.customer_id
	and s.product_id = e.product_id
	and order_date < join_date
	group by s.customer_id

--10.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?	
	select customer_id,
	SUM(case
		when product_name = 'sushi'
		then price * 2 *10
		else price * 10
	    end)as totalpoints
	from menu m, sales s
	where s.product_id = m.product_id
	group by customer_id

--11.In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?

select customer_id , 
	sum(case 
	 when order_date between join_date and valid_date
	 or product_name = 'sushi'
	 then price * 20
	 else price *10
	 end) as totalflow
		from 
		(
		select s.customer_id , e.product_name,join_date , order_date , DATEADD(day,6,join_date) as valid_date , price 
		from members m , sales s , menu e
		where m.customer_id = s.customer_id
		and s.product_id = e.product_id
		and order_date <= EOMONTH('2021-01-01')
		)f
	group by customer_id

--Bonus questions
	--1.
		select s.customer_id , s.order_date , product_name , price ,
		case 
			when order_date >= join_date
			then 'y'
			else 'N'
			end as member
		into newtable
		from sales s 
		left join members m 
		on s.customer_id = m.customer_id
		inner join menu e
		on s.product_id = e.product_id

	--2.
		select customer_id , order_date , product_name , price , member ,
			case
				when ranki = 1 then null
				else member
				end as ranking
		from
		(
		select * , DENSE_RANK() over (partition by customer_id order by member) as ranki
		from newtable
		)f




