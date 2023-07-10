Use Northwind;
-- ======================================== STORE PROCEDURE ========================================
---	Viết stored procedure với Input là một sản phẩm ProductId và 
--Output là một hóa đơn OrderId mà trong hóa đơn đó sản phẩm nhập có UnitPrice là lớn nhất

CREATE PROCEDURE sp_GetOrrderId_HighUnitPrice
	@ProductId INT,
	@OrderId INT OUTPUT,
	@UnitPrice DECIMAL(12, 2) OUTPUT
AS
BEGIN
	WITH ProductInfo(Id, OrderId, UnitPrice, RowNum)
	AS (
		SELECT Id, OrderId, UnitPrice, ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS RowNum
		FROM OrderItem
		WHERE ProductId = @ProductId
	)
	SELECT @OrderId = OrderId, @UnitPrice = UnitPrice
	FROM ProductInfo
END

-- -	Chạy stored procedure này với ProductId là 11 xem kết quả hóa đơn nào mà 
-- product 11 có Unitprice là lớn nhất
DECLARE @ProductId INT
DECLARE @OrderId INT
DECLARE @UnitPrice DECIMAL(12, 2)

SET @ProductId = 21
EXEC sp_GetOrrderId_HighUnitPrice @ProductId, @OrderId OUTPUT, @UnitPrice OUTPUT
SELECT @ProductId AS ProductId, @OrderId AS OrderId, @UnitPrice AS UnitPrice

-- WITH TRANSACTION
---	Viết một stored procedure để thêm một product mới với Input là ProductName, SupplierId, Unit Price và Package. 
--Lưu ý: Nếu SupplierID đó chưa tồn tại hoặc Package là trống thì báo lỗi và Roll Back lại

select * from Product

create procedure sp_InsertNewProduct
	@ProductName nvarchar(50),
	@SupplierId INT,
	@UnitPrice decimal(12, 2),
	@Package nvarchar(30)
as 
begin
	if (not exists(select * from Supplier where Id = @SupplierId))
	begin
		print N'Nha ung cap ' + ltrim(str(@SupplierId)) + N' chua ton tai'
		return -1
	end

	-- neu package la trong thi bao loi va roll back
	if (len(@Package) = 0)
	begin
		print(N' Mo ta dang Package cua nha cung cap' + ltrim(str(@SupplierId)) + N' khong duoc trong')
		return -1
	end

	-- Nếu các kiểm tra trên được thực hiện thành công,
	begin try
		begin transaction 
			insert into [dbo].[Product]([ProductName], [SupplierId], UnitPrice, Package, isDiscontinued)
			values (@ProductName, @SupplierId, @UnitPrice, @Package, 0)
		-- Nếu câu lệnh chèn được thực thi thành công, giao dịch sẽ được xác nhận bằng cách sử dụng COMMIT TRANSACTION, 
		-- và sản phẩm mới sẽ được thêm vào cơ sở dữ liệu.
		commit transaction
	end try
	-- Trong trường hợp xảy ra lỗi trong quá trình chèn, thủ tục sẽ vào khối CATCH
	begin catch
		if @@TRANCOUNT > 0 rollback transaction
		declare @ERR nvarchar(max)
		set @err = ERROR_MESSAGE()
		print N'Co loi sau trong qua trinh them du lieu vao bang Product'
		raiserror (@err, 15, 1);
		return -1
	end catch
end

-- -	Giả sử thêm sản phẩm của nhà cung cấp 100 (Chưa có nhà cung cấp này). 
-- Chương trình sẽ báo lỗi và ROLL BACK lại

declare @stateinsert int
exec @stateinsert = sp_InsertNewProduct 'New Product', 100, 10, 'boxes'	
print(@stateinsert)

---	Thêm một sản phẩm của nhà cung cấp 1 với Package là boxes

declare @stateinsert int
exec @stateinsert = sp_InsertNewProduct 'New Product', 1, 10, 'boxes'	
print(@stateinsert)

select * from [Product]
where ProductName = 'New Product'

select * from [Product]