USE Northwind;

-- 1/ Dùng ROW_NUMBER trong SQL
--	Sắp xếp OrderItem tăng dần theo Quantity và tìm 10% dòng có Quantity cao nhất. 
-- Lưu ý hàm MAX() đi với OVER dùng để lấy thông tin có giá trị lớn nhất theo toàn bộ dữ liệu

SELECT *
FROM (
	SELECT RowNum, Id, OrderId, ProductId, Quantity, 
		max(RowNum) OVER (ORDER BY (SELECT 1)) AS RowLast
	FROM (
		SELECT 
			ROW_NUMBER() OVER (ORDER BY Quantity ASC) AS RowNum,
			Id, OrderId, ProductId, Quantity
		FROM OrderItem
		-- Sắp xếp OrderItem tăng dần theo Quantity
	) AS DerivedTable
) AS Report
WHERE Report.RowNum >= 0.1 * RowLast -- Tìm 10% dòng có Quantity cao nhất

------------------------------------
-- Xuất danh sách các hóa đơn (OrderNumber, OrderDate, CustomerId, TotalAmount) kèm theo
-- thông tin hóa đơn đó có tổng số lượng mua chiếm bao nhiêu % của một khách hàng

SELECT OrderNumber, OrderDate, CustomerId, TotalAmount, STR([Percent]*100, 5, 2) + '%' AS [Percent]
FROM (
	SELECT OrderNumber, OrderDate, CustomerId, TotalAmount, 
		TotalAmount / (SUM(TotalAmount) OVER (PARTITION BY CustomerId)) AS [Percent]
	FROM [Order]
) 
AS Report
ORDER BY CustomerId, OrderDate

-------------------------------------
---	Với mỗi sản phẩm có trong hóa đơn, xuất thông tin 3 hóa đơn có số lượng đặt sản phẩm lớn nhất

SELECT Report.*
FROM (
	SELECT P.Id, P.ProductName, O.Quantity,
		ROW_NUMBER() OVER (PARTITION BY O.ProductId ORDER BY O.Quantity DESC) -- Sắp xếp số lượng giảm dân
		AS RowNum
	FROM OrderItem AS O
	INNER JOIN Product AS P
	ON O.ProductId = P.Id
)
AS Report
WHERE Report.RowNum <= 3
ORDER BY Report.Id

-- 2/ Dùng PIVOT trong SQL
--	Xuất thông tin khách hàng và thông tin số lượng hóa đơn trong các tháng từ 1 đến 12 theo hàng ngang. 
--  Lưu ý ta phải tạo dữ liệu tổng số hóa đơn mỗi tháng theo hàng dọc trước thông qua bảng tạm tên là OrderByMonth. 
--  Bảng này sẽ được kiểm tra cẩn thận trước khi tạo ra và sử dụng

--	Kiểm tra xem bảng OrderByMonth có chưa. Nếu có rồi thì xóa đi sau đó hàm SELECT INTO sẽ tự động tạo lại bảng này. 

IF EXISTS(
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_NAME = N'OrderByMonth'
)
BEGIN
	DROP TABLE OrderByMonth
END

SELECT CustomerId,
	MONTH(OrderDate) AS MonthOrder,
	COUNT(OrderNumber) AS OrderCount
INTO OrderByMonth
FROM [Order]
GROUP BY CustomerId, MONTH(OrderDate)

SELECT *
FROM OrderByMonth

--SELECT * FROM OrderByMonth Order By CustomerId
SELECT * FROM OrderByMonth
PIVOT (COUNT(OrderCount) FOR MonthOrder IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS PivotedOrder

SELECT * FROM OrderByMonth
PIVOT (SUM(OrderCount) FOR MonthOrder IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS PivotedOrder

SELECT CustomerByMonth. CustomerId, C.FirstName + + C. LastName AS [CustomerName],
	ISNULL(CustomerByMonth. [1],0) AS [Order in T1],
	ISNULL(CustomerByMonth. [2],0) AS [Order in T2],
	ISNULL(CustomerByMonth. [3],0) AS [Order in T3], ISNULL(CustomerByMonth. [4],0) AS [Order in T4],
	ISNULL(CustomerByMonth. [5],0) AS [Order in T5],
	ISNULL(CustomerByMonth. [6],0) AS [Order in T6],
	ISNULL(CustomerByMonth. [7],0) AS [Order in T7],
	ISNULL(CustomerByMonth. [8],0) AS [Order in T8],
	ISNULL(CustomerByMonth. [9],0) AS [Order in T9], ISNULL(CustomerByMonth. [10],0) AS [Order in T10],
	ISNULL(CustomerByMonth. [11],0) AS [Order in T11],
	ISNULL(CustomerByMonth. [12],0) AS [Order in T12]
FROM
(
	--SELECT * FROM OrderByMonth Order By CustomerId
	SELECT * FROM OrderByMonth
	PIVOT (SUM(OrderCount) 
	FOR MonthOrder IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) 
	AS PivotedOrder
) CustomerByMonth
INNER JOIN Customer C ON CustomerByMonth. CustomerId = C.Id

-- 3/ Dùng CASE … WHEN
-- Với mỗi sản phẩm có trong hóa đơn, xuất thông tin 3 hóa đơn có số lượng đặt sản phẩm lớn nhất



-- 4/ Dùng CAST và CONVERT

-- 5/ Xếp loại và hạng trong SQL

--	Xuất danh sách các khách hàng và tổng số Total Amount của khách hàng đó có trong các hóa đơn. Chia nhóm các khách hàng thành 3 nhóm dựa trên tổng số Total Amount này

SELECT CustomerID = Report.Id,
	CustomerName = Report.FirstName + SPACE (1) + Report.LastName,
	OverallAmount = Report.OverallAmount,
	[Group] = NTILE (3) OVER (ORDER BY Report.OverallAmount DESC)
FROM
(
	SELECT C.Id, C.FirstName, C. LastName, [OverallAmount] = SUM(ISNULL(TotalAmount,0))
	FROM Customer C
	LEFT JOIN [Order] O 
	ON C.Id = O.CustomerId
	GROUP BY C.Id, C.FirstName, C.LastName
) AS Report







