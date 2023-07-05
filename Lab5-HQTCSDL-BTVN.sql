-- Lab 05: HQTCSD
-- MSSV: 20280083
-- TÊN: LẠI TOÀN THẮNG

USE Northwind;

-- Sử dụng View trong SQL

--1. Tạo các view sau :
--o uvw_DetailProductInOrder với các cột sau OrderId, OrderNumber, OrderDate,
--ProductId, ProductInfo ( = ProductName + Package. Ví dụ: Chai 10 boxes x 20 bags),
--UnitPrice và Quantity

drop view uvw_DetailProductInOrder

CREATE VIEW uvw_DetailProductInOrder
AS
SELECT
    OrderId,
    O.OrderNumber,
    O.OrderDate,
    ProductId,
    P.ProductName + 'x' + ISNULL(P.Package, '') AS ProductInfo,
    OI.UnitPrice,
    OI.Quantity
FROM
    [Order] O
    JOIN OrderItem OI ON O.Id = OI.OrderId
    JOIN Product P ON OI.ProductId = P.Id;


CREATE VIEW uvw_DetailProductInOrder
AS
SELECT
    OrderId,
    O.OrderNumber,
    O.OrderDate,
    ProductId,
    P.ProductName + ' x ' + ISNULL(P.Package, '') AS ProductInfo,
    OI.UnitPrice,
    OI.Quantity
FROM
    [Order] O
    JOIN OrderItem OI 
	ON O.Id = OI.OrderId
    JOIN Product P 
	ON OI.ProductId = P.Id;

SELECT * FROM uvw_DetailProductInOrder

--o uvw_AllProductInOrder với các cột sau OrderId, OrderNumber, OrderDate, ProductList
--(ví dụ “11,42,72” với OrderId 1), và TotalAmount ( = SUM(UnitPrice * Quantity)) theo
--mỗi OrderId (Gợi ý dùng FOR XML PATH để tạo cột ProductList)

CREATE VIEW uvw_AllProductInOrder AS
SELECT
    O.Id AS OrderId,
    O.OrderNumber,
    O.OrderDate,
    STUFF((
        SELECT ',' + CAST(OI.ProductId AS NVARCHAR(MAX))
        FROM OrderItem OI
        WHERE OI.OrderId = O.Id
        FOR XML PATH('')
    ), 1, 1, '') AS ProductList,
    SUM(OI.UnitPrice * OI.Quantity) AS TotalAmount
FROM
    "Order" O
    JOIN OrderItem OI 
	ON O.Id = OI.OrderId
GROUP BY
    O.Id,
    O.OrderNumber,
    O.OrderDate;

SELECT * FROM uvw_AllProductInOrder
-----------------------------------
SELECT Id AS '@Id',
FirstName + ' ' + LastName AS '@Name'
FROM dbo.Customer FOR XML PATH('Customer'), ROOT ('MyCustomers')

--2. Dùng view “uvw_DetailProductInOrder“ truy vấn những thông tin có OrderDate trong tháng 7

SELECT *
FROM uvw_DetailProductInOrder
WHERE MONTH(OrderDate) = 7;


--3. Dùng view “uvw_AllProductInOrder” truy vấn những hóa đơn Order có ít nhất 3 product trở lên
-- Truy vấn những hóa đơn có số dấu phẩy trong ProductList nhiều hơn hoặc bằng 2
-- tức chiều dài của ProductList trừ chiều dài của ProductList khi replace dấu phẩy bằng space >= 2
SELECT *
FROM uvw_AllProductInOrder
WHERE LEN(ProductList) - LEN(REPLACE(ProductList, ',', '')) >= 2;

select * from uvw_AllProductInOrder

UPDATE uvw_AllProductInOrder
SET TotalAmount = 1000
WHERE OrderId = 1

--4. Hai view trên đã readonly chưa ? Có những cách nào làm hai view trên thành readonly ?

drop trigger [uvw_DetailProductInOrder_A_Trigger_OnInsertOrUpdateOrDelete]

CREATE TRIGGER [uvw_DetailProductInOrder_A_Trigger_OnInsertOrUpdateOrDelete]
ON uvw_DetailProductInOrder
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
	RAISERROR('You are not allowed to udpate information through this view', 16, 1)
END

select * from uvw_DetailProductInOrder

UPDATE uvw_DetailProductInOrder SET Quantity = 21
WHERE OrderId = 7;



--5. Thống kê về thời gian thực thi khi gọi hai view trên. View nào chạy nhanh hơn ?

 -- Đo thời gian execute khi gọi view 'uvw_DetailProductInOrder'
 SET STATISTICS TIME ON
 SELECT * FROM uvw_DetailProductInOrder
 SET STATISTICS TIME OFF;

 -- Đo thời gian execute khi gọi view 'uvw_DetailProductInOrder'
 SET STATISTICS TIME ON
 SELECT * FROM uvw_AllProductInOrder
 SET STATISTICS TIME OFF
