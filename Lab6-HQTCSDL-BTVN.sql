USE Northwind;
--1.	Viết hàm truyền vào một CustomerId và xuất ra tổng giá tiền (Total Amount)của các hóa đơn từ khách hàng đó. 
--Sau đó dùng hàm này xuất ra tổng giá tiền từ các hóa đơn của tất cả khách hàng

DROP FUNCTION dbo.GetTotalAmountByCustomerId 

CREATE FUNCTION dbo.GetTotalAmountByCustomerId
(
    @CustomerId INT
)
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(12, 2);

    SELECT @TotalAmount = SUM(O.TotalAmount)
    FROM [Order] O
    WHERE O.CustomerId = @CustomerId;

    RETURN @TotalAmount;
END;

SELECT *, 
	dbo.GetTotalAmountByCustomerId(Id) AS TotalAmount
FROM Customer

SELECT
	DISTINCT Id AS CustomerId, 
	dbo.GetTotalAmountByCustomerId(Id) AS TotalAmount
FROM Customer
ORDER BY CustomerId



--2.	Viết hàm truyền vào hai số và xuất ra danh sách các sản phẩm có UnitPrice nằm trong khoảng hai số đó.

DROP FUNCTION GetProductByUnitPriceRange

CREATE FUNCTION GetProductByUnitPriceRange
(
	@MinPrice DECIMAL(12, 2),
	@MaxPrice DECIMAL(12, 2)
)
RETURNS TABLE
AS
RETURN 
(
	SELECT *
	FROM Product
	WHERE UnitPrice >= @MinPrice
	AND UnitPrice <= @MaxPrice
);

SELECT * FROM GetProductByUnitPriceRange(10, 20)

--3.	Viết hàm truyền vào một danh sách các tháng 'June;July;August;September' và xuất ra thông tin của các hóa đơn
-- có trong những tháng đó. Viết cả hai hàm dưới dạng inline và multi statement sau đó cho biết thời gian thực thi của mỗi hàm,
-- so sánh và đánh giá

-- INLINE FUNCTION
DROP FUNCTION GetOrdersByMonths_Inline

CREATE FUNCTION GetOrdersByMonths_Inline(@MonthsList VARCHAR(MAX))
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM [Order]
    WHERE DATENAME(MONTH, OrderDate) IN (
		SELECT value 
		FROM STRING_SPLIT(@MonthsList, ';')
		)
)

SELECT * FROM GetOrdersByMonths_Inline('June;July;August;September')
-- MULTI STATEMENT FUNCTION
DROP FUNCTION GetOrdersByMonths_MultiStatement

CREATE FUNCTION GetOrdersByMonths_MultiStatement(@MonthList VARCHAR(MAX))
RETURNS @OrdersTable 
TABLE(
	Id INT, 
	OrderDate DATE, 
	OrderNumber NVARCHAR(10), 
	CustomerId INT, 
	TotalAmount DECIMAL(12,2)
)
AS
BEGIN
	SET @MonthList = LOWER(@MonthList)

	INSERT INTO @OrdersTable
	SELECT *
	FROM [Order]
	WHERE CHARINDEX(LTRIM(RTRIM(LOWER(DATENAME(mm, OrderDate)))), LOWER(@MonthList)) > 0
	RETURN
END

SELECT * 
FROM GetOrdersByMonths_MultiStatement('June;July;August;September')
----------------------------------------------------
--CREATE FUNCTION GetOrdersByMonths_MultiStatement (@MonthsList VARCHAR(MAX))
--RETURNS @OrdersTable TABLE
--(
--    OrderId INT,
--    OrderNumber NVARCHAR(100),
--    OrderDate DATE,
--	CustomerId INT,
--	TotalAmount DECIMAL(12,2)
--)
--AS
--BEGIN
--    DECLARE @MonthValues TABLE (MonthName VARCHAR(100))
--    INSERT INTO @MonthValues
--    SELECT value
--    FROM STRING_SPLIT(@MonthsList, ';')

--    INSERT INTO @OrdersTable (OrderId, OrderNumber, OrderDate)
--    SELECT Id, OrderNumber, OrderDate
--    FROM [Order]
--    WHERE DATENAME(MONTH, OrderDate) IN (SELECT MonthName FROM @MonthValues)

--    RETURN;
--END;

--SELECT * FROM GetOrdersByMonths_MultiStatement('June;July;August;September')

SET STATISTICS TIME ON
SELECT * FROM GetOrdersByMonths_Inline('June;July;August;September');
SELECT * FROM GetOrdersByMonths_MultiStatement('June;July;August;September');
SET STATISTICS TIME OFF

--4.	Viết hàm kiểm tra mỗi hóa đơn không có quá 5 sản phẩm (kiểm tra trong bảng OrderItem). 
--Nếu insert quá 5 sản phẩm cho một hóa đơn thì báo lỗi và không cho insert. 

SELECT * FROM OrderItem

DROP FUNCTION ufn_CheckNumberProductOfOrder

CREATE FUNCTION ufn_CheckNumberProductOfOrder(@OrderId INT)
RETURNS BIT
AS
    BEGIN
	    DECLARE @Status BIT, @Count INT;
		SET @Count = (SELECT COUNT(ProductId) FROM OrderItem WHERE OrderId = @OrderId);
		IF( @Count <= 5)
		    SET @Status = 1;
		ELSE
		    SET @Status = 0;

		RETURN @Status;
	END

DROP TRIGGER IF EXISTS CheckNumberProductOfOrderTrigger;

CREATE TRIGGER CheckNumberProductOfOrderTrigger
ON OrderItem
AFTER INSERT
AS
BEGIN
    DECLARE @OrderId INT;
    SELECT @OrderId = OrderId from inserted; 
    IF EXISTS (SELECT 1 FROM inserted WHERE dbo.ufn_CheckNumberProductOfOrder(@OrderId) = 0)
    BEGIN
        RAISERROR('CAN NOT INSERT, NUMBER OF PRODUCT IS AT MOST 5 ITEMS', 16, 1);
        ROLLBACK TRANSACTION
    END
END

INSERT INTO OrderItem VALUES(26 , 12, 7, 3);