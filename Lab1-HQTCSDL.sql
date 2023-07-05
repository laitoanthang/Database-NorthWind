select * from master.dbo.sysdatabases;

use Northwind;


if db_id('Northwind') is null
begin
	select 'database is not exist'
end
else
begin
	select 'database is exist'
end;


---	Truy vấn danh sách các Customer
select *
from Customer;

---	Truy vấn danh sách các Customer theo các thông tin Id, FullName (là kết hợp FirstName-LastName), City, Country
select Id, FirstName + ' ' + LastName as FullName, City, Country
from Customer;

---	Cho biết có bao nhiêu khách hàng từ Germany và UK, đó là những khách hàng nào
select count(*) as [Number of Customer], Country
from Customer
where Country = 'Germany' or Country = 'UK'
group by Country

select *
from Customer
where Country = 'Germany' or Country = 'UK';

---	Liệt kê danh sách khách hàng theo thứ tự tăng dần của FirstName và giảm dần của Country
select *
from Customer
order by FirstName asc, Country desc; 

---	Truy vấn danh sách các khách hàng với ID là 5,10, từ 1-10, và từ 5-10
select *
from Customer
where Id in (5, 10);

select *
from Customer
where Id between 1 and 10;

select *
from Customer
where Id between 5 and 10;
-------------------------
select *
from Customer
where Id in (5, 10)
and Id between 1 and 10
and Id between 5 and 10;

---	Truy vấn các khách hàng ở các sản phẩm (Product) mà đóng gói dưới dạng bottles
--- có giá từ 15 đến 20 mà không từ nhà cung cấp có ID là 16.

select C.Id as [Customer Id], 
	C.FirstName + C.LastName as [Full Name], 
	P.Id as [Product Id], 
	P.ProductName, P.UnitPrice, 
	S.Id as [Supplier Id], 
	S.CompanyName as [Supplier Name], 
	Package
from Customer as C
join [Order] as O
on C.Id = O.CustomerId
join OrderItem as OI
on O.Id = OI.OrderId
join Product as P
on OI.ProductId = P.Id
join Supplier as S
on P.SupplierId = S.Id
where Package like '%bottles%'
and P.UnitPrice between 15 and 20
and S.Id <> 16;
