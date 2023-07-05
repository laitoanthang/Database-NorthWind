-- bai tap huong dan
USE Northwind;

WITH CustomerCategory(Country, City, OrderId, alevel)
AS(
SELECT DISTINCT Country,
City = CAST('' AS NVARCHAR(255)),
OrderId = -1,
alevel = 0
FROM Customer

UNION ALL

SELECT C.Country,
City = CAST(C.City AS NVARCHAR(255)),
OrderId = -1,
alevel = CC.alevel + 1
FROM CustomerCategory CC INNER JOIN Customer C ON CC.Country = C.Country
WHERE CC.alevel = 0

UNION ALL

SELECT C.Country,
City = CAST(C.City AS NVARCHAR(255)),
OrderId = O.Id,
alevel = CC.alevel + 1
FROM CustomerCategory CC INNER JOIN Customer C ON CC.Country = C.Country AND CC.City = C.City INNER JOIN [Order] O ON C.Id = O.CustomerId
WHERE CC.alevel = 1
)
SELECT [Quoc Gia] = CASE WHEN alevel = 0 THEN Country ELSE '--' END,
[Thanh Pho] = CASE WHEN alevel = 1 THEN City ELSE '----' END,
[Order Id] = CASE WHEN alevel = 2 THEN CAST(OrderId AS NVARCHAR) ELSE '------' END,
Cap = alevel
FROM CustomerCategory
GROUP BY Country, City, OrderId, alevel
ORDER BY Country, City, OrderId, alevel


--	: Viết ví dụ dùng SUM OVER để tính tổng theo nhóm mà không cần dùng GROUP BY

SELECT OrderNumber, OrderDate, 
		CustomerId, 
		TotalAmount, 
		SUM(TotalAmount) OVER (PARTITION BY CustomerId) AS TotalAmountByCustomer, 
		CAST((TotalAmount / (SUM(TotalAmount) OVER (PARTITION BY CustomerId)) * 100) AS DECIMAL (6,2)) AS PercentByCustomer
FROM [Order]
ORDER BY CustomerId, OrderNumber

SELECT OrderNumber,
	CustomerId, SUM(TotalAmount)	
FROM [Order]
GROUP BY CustomerId, OrderNumber

-- 2. DUNG DATETIME VA COALESCE
--	Xuất các hóa đơn vào ngày chủ nhật của tháng tám
SELECT DATENAME (dw, OrderDate) AS [Day Name], DATENAME(MONTH, OrderDate) AS [Month Name],*
FROM [Order]
WHERE DATENAME (dw, OrderDate) = 'Sunday' AND DATENAME (MONTH, OrderDate)='August'


--	Xuất thông Supplier gồm CompanyName, ContactName, Country, ContactInfo, 
--	ContactType. Trong đó ContactInfo ưu tiên Fax, nếu không có thì dùng Phone.
--	Còn ContactType ghi chú đó là loại ContactInfo nào

SELECT CompanyName, ContactName, COALESCE(Fax, Phone) AS Contactinfo,
	CASE COALESCE(Fax, Phone) WHEN Fax THEN 'Fax' ELSE 'Phone' END AS ContactType
FROM Supplier

-- 3. DÙNG WITH VỚI ĐỆ QUY TRONG SQL

-- Viết một ví dụ dùng WITH với thao tác đệ quy (xây dựng cây) trong SQLSERVER
-- -	Dùng WITH phân chia cây như sau : 
-- Mức 0 là các Quốc Gia(Country), 
-- mức 1 là các Thành Phố (City) thuộc Country đó, 
-- và mức 2 là các Nhà Cung Cấp (Supplier) thuộc Country-City đó


---	Dùng WITH phân chia cây như sau : Mức 0 là các Quốc Gia(Country), 
--mức 1 là các Thành Phố (City) thuộc Country đó, và 
--mức 2 là các Nhà Cung Cấp (Supplier) thuộc Country-City đó

WITH SupplierCategory(Country, City, CompanyName, alevel)
AS(
	SELECT DISTINCT Country,
		City = CAST('' AS NVARCHAR(255)),
		CompanyName = CAST('' AS NVARCHAR(255)),
		alevel = 0
	FROM Supplier

	UNION ALL
	-- join the cte with the supplier table 
	SELECT S.Country,
		City = CAST(S.City AS NVARCHAR(255)),
		CompanyName = CAST('' AS NVARCHAR(255)),
		alevel = SC.alevel + 1 -- if city is the match the previous one, then increase alevel by 1
	FROM SupplierCategory SC
	INNER JOIN Supplier S 
	ON SC.Country = S.Country
	WHERE SC.alevel = 0

	UNION ALL
	-- match both the country and city selected in the previous step
	SELECT S.Country,
		City = CAST(S.City AS NVARCHAR(255)),
		CompanyName = CAST(S.CompanyName AS NVARCHAR(255)),
		alevel = SC.alevel + 1
	FROM SupplierCategory SC
	INNER JOIN Supplier S 
	ON SC.Country = S.Country AND SC.City = S.City
	WHERE SC.alevel = 1
)
SELECT [Quoc Gia] = CASE WHEN alevel = 0 THEN Country ELSE '--' END,
	[Thanh Pho] = CASE WHEN alevel = 1 THEN City ELSE '----' END,
	[Nha Cung Cap] = CompanyName,
	Cap = alevel
FROM SupplierCategory
ORDER BY Country, City, CompanyName, alevel


-- 4. DÙNG CTE (COMMON TABLE EXPRESSION)
WITH AvgBySupplier AS
(
	SELECT SupplierId, AVGUnitPrice = AVG(UnitPrice)
	FROM Product
	GROUP BY SupplierId
	HAVING SupplierId = 3
), 
ProductByCountry AS
(
	SELECT P.*
	FROM Product P
	INNER JOIN Supplier S ON P.SupplierId = S.Id
	WHERE S.Country = 'Germany'
)
SELECT *
FROM ProductByCountry
WHERE UniQtPrice > ALL (SELECT AVGUnitPrice FROM AvgBySupplier)



with OrderSummary as (
	select sum(Quantity) as 'TotalQuantity' , OrderId
	from [OrderItem] as OI
	group by OrderId
	having sum(Quantity) > 50
	order by OrderId asc
), 
CustomerCountry  as (
	select O.Id, O.OrderDate, OrderNumber, TotalAmount, CustomerId, Country, [Name] = FirstName + ' ' + LastName
	from Customer as C
	join [Order] as O
	on C.Id = O.CustomerId
	where Country like '%France%'
)
select *
from OrderSummary as OS
join CustomerCountry as CC
on OS.OrderId = CC.Id