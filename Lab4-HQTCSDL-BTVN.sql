-- Lab 04: HQTCSD
-- MSSV: 20280083
-- TÊN: LẠI TOÀN THẮNG

USE Northwind;
--      1.	Theo mỗi OrderID cho biết số lượng Quantity của
--		mỗi ProductID chiếm tỷ lệ bao nhiêu phần trăm

SELECT OrderId, ProductId, 
	Quantity, SUM(Quantity) OVER (PARTITION BY OrderId) AS TotalQuantity,
	STR(CAST(Quantity * 100.0 / SUM(Quantity) OVER (PARTITION BY OrderId) AS DECIMAL(5, 2))) + '%' AS PercentQuantityByOrderId
FROM [OrderItem] AS OI

--      2.	Xuất các hóa đơn kèm theo thông tin ngày trong 
--		tuần của hóa đơn là : Thứ 2,3,4,5,6,7, Chủ Nhật

SELECT Id, OrderDate, OrderNumber, CustomerId, TotalAmount, DATENAME(WEEKDAY, OrderDate) AS DayOfWeek
FROM [Order]

--		3.	Với mỗi ProductID trong OrderItem xuất các thông tin gồm OrderID, ProductID, 
--		ProductName, UnitPrice, Quantity, ContactInfo, ContactType. Trong đó ContactInfo ưu tiên Fax,
--		nếu không thì dùng Phone của Supplier sản phẩm đó. Còn ContactType là ghi chú đó là loại ContactInfo nào

SELECT OrderID, ProductId, ProductName, P.UnitPrice, Quantity, COALESCE(Fax, Phone) as 'ContactInfo',
	CASE COALESCE(Fax, Phone)
		WHEN Fax THEN 'Fax' 
		ELSE COALESCE('Phone', 'N/A')
	END AS 'ContactType'
FROM OrderItem as OI
JOIN Product as P
ON OI.ProductId = P.Id
JOIN Supplier as S
ON P.SupplierId = S.Id

SELECT OrderID, ProductId, ProductName, P.UnitPrice, Quantity, COALESCE(Fax, Phone) as 'ContactInfo',
	CASE
		WHEN Fax IS NOT NULL THEN 'Fax'
		ELSE 'Phone'
	END AS 'ContactInfo'
FROM OrderItem as OI
JOIN Product as P
ON OI.ProductId = P.Id
JOIN Supplier as S
ON P.SupplierId = S.Id

--		4.	Cho biết Id của database Northwind, Id của bảng Supplier, Id của User
--		mà bạn đang đăng nhập là bao nhiêu. Cho biết luôn tên User mà đang đăng nhập

-- Id của database Northwind
SELECT DB_ID('Northwind') as 'Database ID'
-- Id của bảng Supplier
SELECT OBJECT_ID('Supplier') as 'Supplier ID'
-- Id của User
SELECT SUSER_ID() as 'User ID'
-- tên User mà đang đăng nhập
SELECT SUSER_SNAME() AS 'User Name'

--		5.	Cho biết các thông tin user_update, user_seek, user_scan 
--		và user_lookup trên bảng Order trong database Northwind

SELECT 
	[TableName] = OBJECT_NAME(object_id),
	user_updates, user_seeks, user_scans, user_lookups
FROM 
	sys.dm_db_index_usage_stats
WHERE 
	database_id = DB_ID('Northwind')
AND 
	OBJECT_NAME(object_id) = 'Order'

SELECT 
    OBJECT_NAME(object_id) AS TableName,
    user_updates,
    user_seeks,
    user_scans,
    user_lookups
FROM 
    sys.dm_db_index_usage_stats
WHERE 
    OBJECT_ID = OBJECT_ID('Order')

--6.	Dùng WITH phân chia cây như sau : Mức 0 là các Quốc Gia(Country), mức 1 là các Thành Phố (City)
--		thuộc Country đó, và mức 2 là các Hóa Đơn (Order) thuộc khách hàng từ Country-City đó
-- DÙNG WITH VỚI ĐỆ QUY ĐỂ XÂY DỰNG CÂY

-- CAST dùng để convert chuyển đổi dữ liệu. Phải dùng nó vì nếu không sẽ hiện lỗi mismatch in the data types 

WITH OrderCategory (Country, City, OrderId, Level)
AS (
    -- Level 0: Countries
    SELECT DISTINCT Country,
        City = CAST('' AS NVARCHAR(255)),
        OrderId = -1,
        Level = 0
    FROM Customer
    
    UNION ALL
    
    -- Level 1: Cities within each Country
    SELECT C.Country,
        City = CAST(C.City AS NVARCHAR(255)),
        OrderId = -1,
        Level = OC.Level + 1
    FROM OrderCategory OC
    INNER JOIN Customer C ON OC.Country = C.Country
    WHERE OC.Level = 0
    
    UNION ALL
    
    -- Level 2: Orders within each City
    SELECT C.Country,
        City = CAST(C.City AS NVARCHAR(255)),
        O.Id AS OrderId,
        Level = OC.Level + 1
    FROM OrderCategory OC
    INNER JOIN Customer C ON OC.Country = C.Country AND OC.City = C.City
    INNER JOIN [Order] O ON C.Id = O.CustomerId
    WHERE OC.Level = 1
)
SELECT [Quoc Gia] = CASE WHEN Level = 0 THEN Country ELSE '--' END,
    [Thanh Pho] = CASE WHEN Level = 1 THEN City ELSE '----' END,
    [Order Id] = CASE WHEN Level = 2 THEN CAST(OrderId AS NVARCHAR) ELSE '------' END,
    Cap = Level
FROM OrderCategory
GROUP BY Country, City, OrderId, Level
ORDER BY Country, City, OrderId, Level;

--7.	Xuất những hóa đơn từ khách hàng France mà có tổng số lượng Quantity
--		lớn hơn 50 của các sản phẩm thuộc hóa đơn ấy

-- Xuất những hóa đơn từ khách hàng France mà có tổng số lượng Quantity lớn hơn 50
-- DÙNG CTE
WITH OrderSummary AS (
	SELECT OrderId, SUM(Quantity) AS 'TotalQuantity'
	FROM [OrderItem]
	GROUP BY OrderId
	HAVING SUM(Quantity) > 50
), 
CustomerCountry AS (
	SELECT O.Id, O.OrderDate, OrderNumber, TotalAmount, CustomerId, Country, [Name] = CONCAT(FirstName, ' ', LastName)
	FROM Customer AS C
	JOIN [Order] AS O
	ON C.Id = O.CustomerId
	WHERE Country LIKE '%France%'
)
SELECT *
FROM OrderSummary AS OS
JOIN CustomerCountry AS CC
ON OS.OrderId = CC.Id;

