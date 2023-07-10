USE Northwind;

--1.	Viết một stored procedure với Input là một mã khách hàng CustomerId và Output là một hóa đơn OrderId của khách hàng đó 
--có Total Amount là nhỏ nhất và một hóa đơn OrderId của khách hàng đó có Total Amount là lớn nhất 
--(Vi du: EXEC usp_GetOrderID_CustomerID_MaxAndMinTotalQuantity @CustomerId,@MaxOrderId OUTPUT,
-- @MaxTotalAmount OUTPUT, @MinOrderId OUTPUT, @MinTotalAmount OUTPUT)
-- Cách 1:
DROP PROCEDURE sp_GetOrderId_TotalAmount_MinAndMax
CREATE PROCEDURE sp_GetOrderId_TotalAmount_MinAndMax
	@CustomerId INT,
	@OrderId INT,
	@TotalAmount DECIMAL(12, 2)
AS
BEGIN
	-- Trả về OrderId và TotalAmount với TotalAmount cao nhất và thấp nhất cho CustomerId đầu vào
	WITH OrderInfo(OrderId, TotalAmount, RowNum)
	AS (
		SELECT Id, TotalAmount, ROW_NUMBER() OVER (ORDER BY TotalAmount DESC) AS RowNum
		FROM [Order]
		WHERE CustomerId = @CustomerId
	)
	SELECT *
	FROM OrderInfo
	WHERE RowNum = 1 OR RowNum = (SELECT MAX(RowNum) FROM OrderInfo);
END

-- Cách 2:
DROP PROCEDURE sp_GetOrderId_TotalAmount_MinAndMax
CREATE PROCEDURE sp_GetOrderId_TotalAmount_MinAndMax
	@CustomerId INT,
	@MinOrderId INT OUTPUT,
	@MinTotalAmount DECIMAL(12, 2) OUTPUT,
	@MaxOrderId INT OUTPUT,
	@MaxTotalAmount DECIMAL(12, 2) OUTPUT
AS
BEGIN
	-- Trả về OrderId và TotalAmount với TotalAmount cao nhất cho CustomerId đầu vào
	WITH OrderInfoMax(OrderId, TotalAmount, RowNum)
	AS (
		SELECT Id, TotalAmount, ROW_NUMBER() OVER (ORDER BY TotalAmount DESC) AS RowNum
		FROM [Order]
		WHERE CustomerId = @CustomerId
	)
	SELECT @MaxOrderId = OrderId, @MaxTotalAmount = TotalAmount
	FROM OrderInfoMax
	WHERE RowNum = 1;

	-- Trả về OrderId và TotalAmount với TotalAmount thấp nhất cho CustomerId đầu vào
	WITH OrderInfoMin(OrderId, TotalAmount, RowNum)
	AS (
		SELECT Id, TotalAmount, ROW_NUMBER() OVER (ORDER BY TotalAmount ASC) AS RowNum
		FROM [Order]
		WHERE CustomerId = @CustomerId
	)
	SELECT @MinOrderId = OrderId, @MinTotalAmount = TotalAmount
	FROM OrderInfoMin
	WHERE RowNum = 1;
END

-- Chạy stored procedure này với CustomerId là 11 xem kết quả hóa đơn nào mà 
-- CustomerId 11 có TotalAmount là lớn nhất và nhỏ nhất

DECLARE @MinOrderId INT;
DECLARE @MinTotalAmount DECIMAL(12, 2);
DECLARE @MaxOrderId INT;
DECLARE @MaxTotalAmount DECIMAL(12, 2);

EXEC sp_GetOrderId_TotalAmount_MinAndMax @CustomerId = 11,
	@MinOrderId = @MinOrderId OUTPUT,
	@MinTotalAmount = @MinTotalAmount OUTPUT,
	@MaxOrderId = @MaxOrderId OUTPUT,
	@MaxTotalAmount = @MaxTotalAmount OUTPUT;

SELECT 'Min' AS Type, @MinOrderId AS OrderId, @MinTotalAmount AS TotalAmount
UNION ALL
SELECT 'Max' AS Type, @MaxOrderId AS OrderId, @MaxTotalAmount AS TotalAmount;

-- Cách 3:
SELECT * FROM [Order]

DROP PROCEDURE sp_GetOrderId_MaxAndMinTotalAmount
CREATE PROCEDURE sp_GetOrderId_MaxAndMinTotalAmount
	@CustomerId INT,
	@MaxOrderId INT OUTPUT,
	@MaxTotalAmount DECIMAL(12, 2) OUTPUT,
	@MinOrderId INT OUTPUT,
	@MinTotalAmount DECIMAL(12, 2) OUTPUT
AS
BEGIN
	-- Tìm hóa đơn có Total Amount lớn nhất cho CustomerId đã cho
	SELECT TOP 1 @MaxOrderId = Id, @MaxTotalAmount = TotalAmount
	FROM [Order]
	WHERE CustomerId = @CustomerId
	ORDER BY TotalAmount DESC;

	-- Tìm hóa đơn có Total Amount nhỏ nhất cho CustomerId đã cho
	SELECT TOP 1 @MinOrderId = Id, @MinTotalAmount = TotalAmount
	FROM [Order]
	WHERE CustomerId = @CustomerId
	ORDER BY TotalAmount ASC;
END

-- Chạy stored procedure này với CustomerId là 11 xem kết quả hóa đơn nào mà 
-- CustomerId 11 có TotalAmount là lớn nhất và nhỏ nhất

DECLARE @MinOrderId INT;
DECLARE @MinTotalAmount DECIMAL(12, 2);
DECLARE @MaxOrderId INT;
DECLARE @MaxTotalAmount DECIMAL(12, 2);

EXEC sp_GetOrderId_MaxAndMinTotalAmount @CustomerId = 11,
	@MinOrderId = @MinOrderId OUTPUT,
	@MinTotalAmount = @MinTotalAmount OUTPUT,
	@MaxOrderId = @MaxOrderId OUTPUT,
	@MaxTotalAmount = @MaxTotalAmount OUTPUT;

SELECT 'Min' AS Type, @MinOrderId AS OrderId, @MinTotalAmount AS TotalAmount
UNION ALL
SELECT 'Max' AS Type, @MaxOrderId AS OrderId, @MaxTotalAmount AS TotalAmount;

--2.	Viết một stored procedure để thêm vào một Customer với Input là FirstName, LastName, City, Country, và Phone. 
-- Lưu ý nếu các input mà rỗng hoặc Input đó đã có trong bảng thì báo lỗi tương ứng và ROLL BACK lại

CREATE PROCEDURE sp_InsertCustomer
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50),
	@City NVARCHAR(50),
	@Country NVARCHAR(50),
	@Phone NVARCHAR(20)
AS
BEGIN
	-- Nếu các input mà rỗng
	IF @FirstName IS NULL OR @FirstName = ''
		OR @LastName IS NULL OR @LastName = ''
		OR @City IS NULL OR @City = ''
		OR @Country IS NULL OR @Country = ''
		OR @Phone IS NULL OR @Phone = ''
	BEGIN
		PRINT N'Vui lòng cung cấp thông tin đầy đủ của khách hàng';
		RETURN -1;
	END
	
	-- Nếu Input đó đã có trong bảng
	IF EXISTS(
		SELECT * FROM Customer
		WHERE @FirstName = FirstName
		AND @LastName = LastName
		AND @Phone = Phone
	)
	BEGIN
		PRINT N'Khách hàng đã tồn tại trong hệ thống'
		RETURN -1
	END

	-- Nếu các kiểm tra trên được thực hiện thành công
	BEGIN TRY
		BEGIN TRANSACTION
			-- Thêm thông tin khách hàng vào
			INSERT INTO Customer(FirstName, LastName, City, Country, Phone)
			VALUES (@FirstName, @LastName, @City, @Country, @Phone)
		-- Nếu câu lệnh chèn được thực thi thành công, 
		-- transaction sẽ được xác nhận bằng cách sử dụng COMMIT TRANSACTION, 
		-- và thông tin khách hàng mới sẽ được thêm vào cơ sở dữ liệu.
		COMMIT TRANSACTION
	END TRY
	-- Trong trường hợp xảy ra lỗi trong quá trình chèn, thủ tục sẽ vào khối CATCH
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorMessage NVARCHAR(MAX);
		SET @ErrorMessage = ERROR_MESSAGE();

		PRINT N'Có lỗi xảy ra khi thêm khách hàng: ' + @ErrorMessage;
		RAISERROR (@ErrorMessage, 15, 1);
		RETURN -1
	END CATCH
END

-- Giả sử thêm khách hàng (Chưa có khách hàng này). 
-- Nhưng điền thông tin không đủ
-- Chương trình sẽ báo lỗi và ROLL BACK lại

DECLARE @StateInsert INT
EXEC @StateInsert = sp_InsertCustomer 'Thang', 'Lai', NULL, 'TP HCM', '0123456789'
PRINT(@StateInsert)

-- Giả sử thêm khách hàng. 
-- Nhưng thông tin đã có trong cơ sở dữ liệu
-- Chương trình sẽ báo lỗi và ROLL BACK lại

DECLARE @StateInsert INT
EXEC @StateInsert = sp_InsertCustomer 'Maria', 'Anders', 'Berlin', 'Germany', '030-0074321'
PRINT(@StateInsert)

-- Giả sử thêm khách hàng (Chưa có khách hàng này). 
-- Với đầy đủ thông tin như sau

DECLARE @StateInsert INT
EXEC @StateInsert = sp_InsertCustomer 'Thang', 'Lai', 'Viet Nam', 'TP HCM', '0123456789'
PRINT(@StateInsert)

SELECT *
FROM [Customer]
WHERE FirstName = 'Thang'

--3.	Viết Store Procedure cập nhật lại UnitPrice của sản phẩm trong bảng OrderItem. 
-- Khi cập nhật lại UnitPrice này thì cũng phải cập nhật lại Total Amount trong bảng Order 
-- tương ứng với Total Amount = SUM (UnitPrice * Quantity)
DROP PROCEDURE sp_UpdateUnitPriceAndTotalAmount

CREATE PROCEDURE sp_UpdateUnitPriceAndTotalAmount
	@ProductId INT,
	@NewUnitPrice DECIMAL(12, 2)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		-- Cập nhật UnitPrice của sản phẩm trong bảng OrderItem
		UPDATE OrderItem
		SET UnitPrice = @NewUnitPrice
		WHERE ProductId = @ProductId;

		-- Cập nhật lại TotalAmount trong bảng Order tương ứng với TotalAmount = SUM(UnitPrice * Quantity)
		UPDATE [Order]
		SET TotalAmount = (
			SELECT SUM(UnitPrice * Quantity)
			FROM OrderItem
			WHERE OrderId = [Order].Id
		)
		WHERE Id IN (
			SELECT OrderId
			FROM OrderItem
			WHERE ProductId = @ProductId
		);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- kiểm tra xem có đang tồn tại một giao dịch đang chạy hay không
		DECLARE @ErrorMessage NVARCHAR(MAX);
		SET @ErrorMessage = ERROR_MESSAGE();

		PRINT N'Có lỗi xảy ra khi cập nhật: ' + @ErrorMessage;
		RAISERROR (@ErrorMessage, 16, 1);
		RETURN -1
	END CATCH;
END

-- Execute stored procedure để update UnitPrice và TotalAmount
EXEC sp_UpdateUnitPriceAndTotalAmount @ProductId = 7, @NewUnitPrice = 35;

-- Kiểm tra kết quả cập nhật bằng cách truy vấn dữ liệu
SELECT * FROM OrderItem WHERE ProductId = 7;

SELECT * FROM [Order] 
WHERE Id IN (
	SELECT OrderId FROM OrderItem 
	WHERE ProductId = 7
	);