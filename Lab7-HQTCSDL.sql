use Northwind;
--1/ Sử dụng Trigger 
--Yêu cầu: Viết ví dụ sử dụng trigger để kiểm soát dữ liệu
--Hướng dẫn: 
---	Tạo một trigger để kiểm tra việc khi xóa một Customer thì thông tin Order của Customer đó sẽ chuyển về cho CustomerId là 1 

CREATE TRIGGER [dbo].[Trigger CustomerDelete]
ON [dbo].[Customer] -- trên bảng customer
FOR DELETE -- khi có lệnh delete
AS

DECLARE @DeletedCustomerID INT -- khai báo biến kiểu int để lưu customerid đã xóa
SELECT @DeletedCustomerID = Id FROM deleted

UPDATE [Order] SET CustomerId = 1 -- update customerID = 1 với các customerID = customerID đã xóa
WHERE CustomerId = @DeletedCustomerID

PRINT 'Cac hoa don cua khach hang CustomerId = ' + LTRIM(STR(@DeletedCustomerID)) + ' da chuyen qua cho CustomerID = 1'; 
-- chuyển đổi giá trị @DeletedCustomerID thành chuỗi và loại bỏ các khoảng trắng thừa (nếu có).




SELECT * FROM [Order] Where CustomerId = 79

select * from [Order] Where Id in (2, 191, 199, 301, 361, 720)

-- Drop the FK_ORDER_REFERENCE_CUSTOMER constraint
ALTER TABLE [Order]
DROP CONSTRAINT FK_ORDER_REFERENCE_CUSTOMER;


delete from Customer where Id = 79;

select * from [Order] Where Id in (2, 191, 199, 301, 361, 720)