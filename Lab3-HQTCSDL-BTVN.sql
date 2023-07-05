USE Northwind;
--	1. Sắp xếp sản phẩm tăng dần theo UnitPrice, và tìm 20% dòng có UnitPrice cao nhất (Lưu ý: Dùng ROW_NUMBER )
SELECT *
FROM (
	SELECT RowNum, Id, ProductId, Quantity, UnitPrice, MAX(RowNum) OVER() as RowLast
	FROM (
		SELECT ROW_NUMBER() OVER (ORDER BY UnitPrice ASC) AS RowNum, *
		FROM OrderItem
	) AS  DerivedTable
) AS Report 
WHERE Report.RowNum >= 0.8 * RowLast
-- Vì sắp xếp UnitPrice tăng dần và chỉ lấy 20% nên
-- select các dòng ở dưới của table (>= 80%)

SELECT *
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY UnitPrice ASC) AS RowNum,
           Id, ProductId, Quantity, UnitPrice,
           COUNT(*) OVER () AS TotalRows
    FROM OrderItem
) AS DerivedTable
WHERE RowNum >= 0.8 * TotalRows;

--	2. Với mỗi hóa đơn, xuất danh sách các sản phẩm, số lượng (Quantity) 
--  và số phần trăm của sản phẩm đó trong hóa đơn. 
--  (Gợi ý: ta lấy Quantity chia cho tổng Quantity theo hóa đơn * 100 + ‘%’. Dùng SUM … OVER)

SELECT P.ProductName, OI.Quantity, OrderId, (SUM(Quantity) OVER(PARTITION BY OrderID)) as SumQuantity,
	STR(Quantity * 100.0 / (SUM(Quantity) OVER(PARTITION BY OrderID)), 5, 2) + '%' as [Percent]
FROM OrderItem as OI
JOIN Product as P
ON OI.ProductId = P.Id
ORDER BY  OrderId

--	3. Xuất danh sách các nhà cung cấp kèm theo các cột USA, UK, France, Germany, Others. 
--  Nếu nhà cung cấp nào thuộc các quốc gia  này thì ta đánh số 1 còn lại là 0 

--  (Gợi ý: Tạo bảng tạm theo chiều dọc trước với tên nhà cung cấp và thuộc quốc gia USA,
--  UK, France, Germany hay Others.

IF EXISTS (
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_NAME = N'OrderByCountry'
)
BEGIN
	DROP TABLE OrderByCountry
END

SELECT S.Country, S.CompanyName
INTO OrderByCountry
FROM [Supplier] as S
ORDER BY Country
-- Kết quả theo chiều dọc
SELECT * FROM OrderByCountry
-- Vì yêu cầu đề bài chỉ có một vài nước nên tạo thêm bảng tạm mới

IF EXISTS (
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_NAME = N'SupplierCountry'
)
BEGIN
	DROP TABLE SupplierCountry
END

SELECT CompanyName, 
	CASE  -- Phân loại nhà cung cấp theo quốc gia
		WHEN Country = 'USA' THEN 'USA' 
		WHEN Country = 'UK' THEN 'UK' 
		WHEN Country = 'France' THEN 'France' 
		WHEN Country = 'Germany' THEN 'Germany' 
		ELSE 'Others' 
	END AS CountryGroup
INTO SupplierCountry
FROM OrderByCountry

SELECT *
FROM SupplierCountry
ORDER BY CompanyName
--  Sau đó PIVOT bảng tạm này để tạo kết quả theo chiều ngang)

SELECT CompanyName, 
	ISNULL([USA], 0) AS USA, 
	ISNULL([UK], 0) AS UK, 
	ISNULL([France], 0) AS France, 
	ISNULL([Germany], 0) AS Germany, 
	ISNULL([Others], 0) AS Others
FROM SupplierCountry
PIVOT (
	COUNT(CountryGroup)
	FOR CountryGroup IN ([USA], [UK], [France], [Germany], [Others])
) AS PivotTable
ORDER BY CompanyName

--	4. Xuất danh sách các hóa đơn gồm OrderNumber, OrderDate (format: dd mm yyyy), CustomerName, 
-- Address (format: “Phone: …… , City: …. and Country: ….”), TotalAmount làm tròn không chữ số thập phân và đơn vị theo kèm là Euro) 

-- USING LTRIM (REMOVE SPACE AND CAST TO CONVERT TO OTHER DATA TYPE)
SELECT OrderNumber, OrderDate, C.FirstName + ' ' + C.LastName as Name,
	'Phone: ' + C.Phone + ', City: ' + C.City + ', Country: ' + C.Country as Address,
	LTRIM(STR(CAST(O.TotalAmount AS varchar(10)))) + ' Euro' as TotalAmount 
FROM [Order] AS O
JOIN Customer AS C
ON O.CustomerId = C.Id

-- USING CONVERT
SELECT OrderNumber, OrderDate, C.FirstName + ' ' + C.LastName as Name,
	'Phone: ' + C.Phone + ', City: ' + C.City + ', Country: ' + C.Country as Address,
	CONVERT(varchar(10), O.TotalAmount) + ' Euro' as TotalAmount 
FROM [Order] AS O
JOIN Customer AS C
ON O.CustomerId = C.Id

-- USING CONCAT INSTEAD OF +
SELECT OrderNumber, OrderDate, CONCAT(C.FirstName, ' ', C.LastName) AS Name,
	CONCAT('Phone: ', C.Phone, ', City: ', C.City, ', Country: ', C.Country) AS Address,
	CONCAT(LTRIM(STR(CAST(O.TotalAmount AS varchar(10)))), ' Euro') AS TotalAmount 
FROM [Order] AS O
JOIN Customer AS C
ON O.CustomerId = C.Id

--	5. Xuất danh sách các sản phẩm dưới dạng đóng gói bags. Thay đổi chữ bags thành ‘túi’ 
--  (Lưu ý: để dùng tiếng việt có dấu ta ghi chuỗi dưới dạng N’túi’)

-- USING REPLACE
SELECT ProductName, UnitPrice,
	Package,
	REPLACE(Package, N'bags', N'túi') AS NewPackage
FROM Product
WHERE Package LIKE N'%bag%'

-- USING STUFF
SELECT ProductName, STUFF(Package, CHARINDEX('bags', Package), LEN('bags'), N'túi') AS NewPackage
FROM Product
WHERE Package LIKE '%bags%';

--	6. Xuất danh sách các khách hàng theo tổng số hóa đơn mà khách hàng đó có, 
--  sắp xếp theo thứ tự giảm dần của tổng số hóa đơn,  kèm theo đó là  
--  các thông tin phân hạng DENSE_RANK và nhóm (chia thành 3 nhóm) (Gợi ý: dùng NTILE(3) để chia nhóm. 

-- USING THE CODE SAMPLE
SELECT CustomerID = Report.Id,
	CustomerName = Report.Name,
	[Number Of Order] = Report.[Number Of Order],
	[Group] = NTILE (3) OVER (ORDER BY Report.[Number Of Order] DESC)
FROM (
	SELECT C.Id, [Name] = CONCAT(C.FirstName, ' ', C.LastName),
		[Number Of Order] = COUNT(ISNULL(O.Id, 0))
	FROM Customer AS C
	LEFT JOIN [Order] AS O
	ON C.Id = O.CustomerId
	GROUP BY C.Id, C.FirstName, C.LastName
	) AS Report

-- USING DENSE RANK() AND NTILE(3)
SELECT C.Id AS CustomerID, CONCAT(C.FirstName, ' ', C.LastName) AS CustomerName, 
	COUNT(O.Id) AS [Number of Orders], 
	DENSE_RANK() OVER (ORDER BY COUNT(O.Id) DESC) AS CustomerRank,
	NTILE(3) OVER (ORDER BY COUNT(ISNULL(O.Id, 0)) DESC) AS GroupNumber
FROM Customer C
LEFT JOIN [Order] O ON C.Id = O.CustomerId
GROUP BY C.Id, C.FirstName, C.LastName
ORDER BY [Number of Orders] DESC