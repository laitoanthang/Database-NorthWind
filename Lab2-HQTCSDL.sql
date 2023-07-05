use Northwind;

if db_id('Northwind') is null
begin 
	select 'databse is not exist'
end
else
begin
	select 'database is exist'
end;


-- Su dung UNION, INTERSECT va EXCEPT

SELECT ORDERNUMBER, TOTALAMOUNT, 'ABOVE AVERAGE' AS [DESCRIPTION]
FROM [ORDER]
WHERE TOTALAMOUNT >= (
	SELECT AVG(TOTALAMOUNT)
	FROM [ORDER]
)
UNION
SELECT ORDERNUMBER, TOTALAMOUNT, 'BELOW AVERAGE' AS [DESCRIPTION]
FROM [ORDER]
WHERE TOTALAMOUNT < (
	SELECT AVG(TOTALAMOUNT)
	FROM [ORDER]
)

SELECT OrderNumber, TotalAmount,
CASE
	WHEN TotalAmount >= (SELECT AVG(TotalAmount) FROM [Order]) THEN 'Above Average'
	ELSE 'Below Average'
END AS [Description]
FROM [Order]

SELECT OrderNumber, TotalAmount,
IIF(TotalAmount >= (SELECT AVG(TotalAmount) FROM [Order]), 'Above Average', 'Below Average') AS [Description]
FROM [Order]

-- Su dung IN, ALL, EXISTS
--- Xuất danh sách các sản phẩm có nhà cung cấp nhiều thứ 4 trong các nhà cung cấp 

select top 4 SupplierId 
from Product
group by SupplierId
order by count(ProductName) desc;

---	Xuất danh sách các khách hàng có hóa đơn vào tháng 7 
select *
from Customer as C
join [Order] as O
on C.Id = O.Id
and month(O.OrderDate) = 7;

select *
from Customer as C
where exists (
	select *
	from [Order] as O
	where C.Id = O.Id
	and month(O.OrderDate) = 7
);

-------------------------- BAI TAP ----------------------------

---	Xuat danh sach cac nha cung cap (gom Id, CompanyName, ContactName, City, Country, Phone) 
--- kem theo gia min va max cua cac san pham ma nha cung cap do cung cap. 
--- Co sap xep theo thu tu Id cua nha cung cap 
--- (Goi y : Join hai ban Supplier va Product, dung GROUP BY tinh Min, Max)
--- Su dung JOIN va GROUP BY
select S.Id, S.CompanyName, S.ContactName, S.City, S.Country, S.Phone, min(P.UnitPrice) as [Min], max(P.UnitPrice) as [Max]
from Supplier as S
join Product as P
on S.Id = P.SupplierId
group by S.Id, S.CompanyName, S.ContactName, S.City, S.Country, S.Phone
order by S.Id;

---	Cũng câu trên nhưng chỉ xuất danh sách nhà cung cấp có 
--- sự khác biệt giá (max – min) không quá lớn (<=30).(Gợi ý: Dùng HAVING)

SELECT S.Id, S.CompanyName, S.ContactName, S.City, S.Country, S.Phone, MIN(P.UnitPrice) AS [MinPrice], MAX(P.UnitPrice) AS [MaxPrice]
FROM Supplier AS S
JOIN Product AS P ON P.SupplierId = S.Id
GROUP BY S.Id, S.CompanyName, S.ContactName, S.City, S.Country, S.Phone
HAVING MAX(P.UnitPrice) - MIN(P.UnitPrice) <= 30
ORDER BY S.Id;



---	Xuất danh sách các hóa đơn (Id, OrderNumber, OrderDate) 
--- kèm theo tổng giá chi trả (UnitPrice*Quantity) cho hóa đơn đó,
--- bên cạnh đó có cột Description 
--- là “VIP” nếu tổng giá lớn hơn 1500 
--- và “Normal” nếu tổng giá nhỏ hơn 1500(Gợi ý: Dùng UNION)
--- Su dung UNION, INTERSECT va EXCEPT

SELECT O.Id, O.OrderNumber, O.OrderDate, (OI.UnitPrice*OI.Quantity) AS TotalPrice, 'VIP' AS [Dscription]
FROM [Order] AS O
INNER JOIN OrderItem AS OI ON O.Id = OI.OrderId
GROUP BY O.Id, O.OrderNumber, O.OrderDate, (OI.UnitPrice*OI.Quantity)
HAVING (OI.UnitPrice*OI.Quantity) > 1500
UNION
SELECT O.Id, O.OrderNumber, O.OrderDate, (OI.UnitPrice*OI.Quantity) AS TotalPrice, 'Normal' AS [Dscription]
FROM [Order] AS O
INNER JOIN OrderItem AS OI ON O.Id = OI.OrderId
GROUP BY O.Id, O.OrderNumber, O.OrderDate, (OI.UnitPrice*OI.Quantity)
HAVING (OI.UnitPrice*OI.Quantity) <= 1500




select O.Id, O.OrderNumber, O.OrderDate, OI.UnitPrice * OI.Quantity as [Tong Gia Chi Tra], 'VIP' as [Description]
from [Order] as O
join OrderItem as OI
on O.Id = OI.OrderId
where OI.UnitPrice * OI.Quantity >= 1500
UNION
select O.Id, O.OrderNumber, O.OrderDate, OI.UnitPrice * OI.Quantity as [Tong Gia Chi Tra], 'Normal' as [Description]
from [Order] as O
join OrderItem as OI
on O.Id = OI.OrderId
where OI.UnitPrice * OI.Quantity < 1500;

-- Sử dụng case when
select O.Id, O.OrderNumber, O.OrderDate, OI.UnitPrice * OI.Quantity as [Tong Gia Chi Tra],
	(case
		when OI.UnitPrice * OI.Quantity >= 1500 then 'VIP'
		else 'Normal'
	end) as [Description]
from [Order] as O
join OrderItem as OI
on O.Id = OI.OrderId;

select O.Id, O.OrderNumber, O.OrderDate, OI.UnitPrice * OI.Quantity as [Tong Gia Chi Tra],
	IIF ((OI.UnitPrice * OI.Quantity >= 1500), 'VIP', 'Normal') as Description
from [Order] as O
join OrderItem as OI
on O.Id = OI.OrderId;

---	Xuất danh sách những hóa đơn (Id, OrderNumber, OrderDate) trong tháng 7 
--- nhưng phải ngoại trừ ra những hóa đơn từ khách hàng France. (Gợi ý: dùng EXCEPT)
--- Su dung UNION, INTERSECT va EXCEPT

select O.Id, O.OrderNumber, O.OrderDate
from [Order] as O
where month(O.OrderDate) = 7
except
select O.Id, O.OrderNumber, O.OrderDate
from [Order] as O
join Customer as C
on O.CustomerId = C.Id
where C.Country = 'France';

SELECT O.Id, O.OrderNumber, O.OrderDate, C.Country
FROM [Order] AS O
INNER JOIN Customer as C ON C.Id = O.CustomerId
WHERE MONTH(OrderDate) = 7
EXCEPT
SELECT O.Id, O.OrderNumber, O.OrderDate, C.Country
FROM [Order] AS O
INNER JOIN Customer as C ON C.Id = O.CustomerId
WHERE C.Country = 'France'


---	Xuất danh sách những hóa đơn (Id, OrderNumber, OrderDate, TotalAmount)
--- nào có TotalAmount nằm trong top 5 các hóa đơn. (Gợi ý : Dùng IN)
select O.Id, O.OrderNumber, O.OrderDate, O.TotalAmount
from [Order] as O
where TotalAmount in (
	select Top 5 TotalAmount
	from [Order] as O
	order by TotalAmount desc
);

SELECT Id, OrderNumber, TotalAmount, TotalAmount
FROM [Order]
WHERE TotalAmount IN (SELECT TOP 5 TotalAmount FROM [Order] ORDER BY TotalAmount DESC)