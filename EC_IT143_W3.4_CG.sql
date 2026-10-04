/*****************************************************************************************************************
NAME:    AdventureWorks_Create_Answers.sql
PURPOSE: Answer eight AdventureWorks business and metadata questions using Transact-SQL.

MODIFICATION LOG:
Ver      Date        Author                      Description
-----    ----------  --------------------------  -----------------------------------------------------------------------
1.0      10/03/2026  Constance Bonjesi Gakaka   Created script for AdventureWorks Create Answers assignment.

RUNTIME:
Approximately 1–5 seconds, depending on system performance.

NOTES:
This script answers eight AdventureWorks questions selected from the previous Create Questions assignment.
It contains two questions from each required category:
1. Business User Questions – Marginal Complexity
2. Business User Questions – Moderate Complexity
3. Business User Questions – Increased Complexity
4. Metadata Questions using INFORMATION_SCHEMA views

Question source mix:
- Q1 and Q2: Eugene Offei Awuku
- Q3 and Q5: Constance Bonjesi Gakaka (own questions)
- Q4, Q6 and Q7: Kayega Musa
- Q8: Rodrigue Kpelly

No more than two questions are the author's own questions.
The remaining six questions were submitted by other students.
*****************************************************************************************************************/

USE AdventureWorks2022;
GO

-- ===============================================================================================================
-- Q1 BUSINESS USER QUESTION – MARGINAL COMPLEXITY
-- Original Author: Eugene Offei Awuku
-- Question Source: Another student
--
-- Original Question:
-- Which 10 products have the highest list prices?
--
-- A1:
-- This query returns the ten products with the highest list prices,
-- ordered from highest to lowest list price.
-- ===============================================================================================================

SELECT TOP (10)
       ProductID,
       Name AS ProductName,
       ListPrice
FROM Production.Product
ORDER BY
       ListPrice DESC,
       Name ASC;
GO

-- ===============================================================================================================
-- Q2 BUSINESS USER QUESTION – MARGINAL COMPLEXITY
-- Original Author: Eugene Offei Awuku
-- Question Source: Another student
--
-- Original Question:
-- Which products have the highest standard costs?
--
-- A2:
-- This query identifies every product whose StandardCost equals
-- the maximum StandardCost recorded in Production.Product.
-- ===============================================================================================================

SELECT
       ProductID,
       Name AS ProductName,
       StandardCost
FROM Production.Product
WHERE StandardCost =
(
    SELECT MAX(StandardCost)
    FROM Production.Product
)
ORDER BY
       Name ASC;
GO

-- ===============================================================================================================
-- Q3 BUSINESS USER QUESTION – MODERATE COMPLEXITY
-- Original Author: Constance Bonjesi Gakaka
-- Question Source: My own question
--
-- Original Question:
-- Which five products generated the highest total sales value?
-- Use SalesOrderDetail and Product to identify each product and its combined LineTotal.
--
-- A3:
-- This query joins sales-order details to products, totals LineTotal for each product,
-- and returns the five products that generated the highest total sales value.
-- ===============================================================================================================

SELECT TOP (5)
       p.ProductID,
       p.Name AS ProductName,
       SUM(sod.LineTotal) AS TotalSalesValue
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
GROUP BY
       p.ProductID,
       p.Name
ORDER BY
       TotalSalesValue DESC,
       p.Name ASC;
GO

-- ===============================================================================================================
-- Q4 BUSINESS USER QUESTION – MODERATE COMPLEXITY
-- Original Author: Kayega Musa
-- Question Source: Another student
--
-- Original Question:
-- We are reviewing category performance. Which bicycle subcategories generated
-- the most sales revenue during 2013?
--
-- A4:
-- This query calculates 2013 sales revenue for each bicycle subcategory
-- and ranks the subcategories from highest to lowest revenue.
-- ===============================================================================================================

SELECT
       psc.Name AS BicycleSubcategory,
       SUM(sod.LineTotal) AS TotalSalesRevenue
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Sales.SalesOrderHeader AS soh
    ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE soh.OrderDate >= '20130101'
  AND soh.OrderDate < '20140101'
  AND pc.Name = 'Bikes'
GROUP BY
       psc.Name
ORDER BY
       TotalSalesRevenue DESC,
       psc.Name ASC;
GO

-- ===============================================================================================================
-- Q5 BUSINESS USER QUESTION – INCREASED COMPLEXITY
-- Original Author: Constance Bonjesi Gakaka
-- Question Source: My own question
--
-- Original Question:
-- Management is reviewing product demand to guide future inventory planning.
-- Identify the five products with the greatest total quantity ordered across all sales orders.
-- For each product, report its name and total units ordered so management can see
-- which products experience the strongest demand.
--
-- A5:
-- This query totals the order quantity for every product and returns
-- the five products with the greatest number of units ordered.
-- ===============================================================================================================

SELECT TOP (5)
       p.ProductID,
       p.Name AS ProductName,
       SUM(sod.OrderQty) AS TotalUnitsOrdered
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
GROUP BY
       p.ProductID,
       p.Name
ORDER BY
       TotalUnitsOrdered DESC,
       p.Name ASC;
GO

-- ===============================================================================================================
-- Q6 BUSINESS USER QUESTION – INCREASED COMPLEXITY
-- Original Author: Kayega Musa
-- Question Source: Another student
--
-- Original Question:
-- A regional manager is preparing next year's sales plan. For every territory,
-- identify the salesperson who generated the highest total sales in 2013 and report
-- the salesperson's name, territory name, and sales amount.
--
-- A6:
-- This query totals each salesperson's 2013 sales within each territory,
-- ranks salespeople inside each territory, and returns the highest-selling
-- salesperson for every territory.
-- ===============================================================================================================

WITH SalespersonTotals AS
(
    SELECT
           st.TerritoryID,
           st.Name AS TerritoryName,
           soh.SalesPersonID,
           CONCAT(pp.FirstName, ' ', pp.LastName) AS SalespersonName,
           SUM(soh.TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    INNER JOIN Sales.SalesPerson AS sp
        ON soh.SalesPersonID = sp.BusinessEntityID
    INNER JOIN Person.Person AS pp
        ON sp.BusinessEntityID = pp.BusinessEntityID
    WHERE soh.OrderDate >= '20130101'
      AND soh.OrderDate < '20140101'
      AND soh.SalesPersonID IS NOT NULL
    GROUP BY
           st.TerritoryID,
           st.Name,
           soh.SalesPersonID,
           pp.FirstName,
           pp.LastName
),
RankedSalespeople AS
(
    SELECT
           TerritoryID,
           TerritoryName,
           SalesPersonID,
           SalespersonName,
           TotalSales,
           DENSE_RANK() OVER
           (
               PARTITION BY TerritoryID
               ORDER BY TotalSales DESC
           ) AS SalesRank
    FROM SalespersonTotals
)
SELECT
       TerritoryName,
       SalespersonName,
       TotalSales
FROM RankedSalespeople
WHERE SalesRank = 1
ORDER BY
       TerritoryName,
       SalespersonName;
GO

-- ===============================================================================================================
-- Q7 METADATA QUESTION
-- Original Author: Kayega Musa
-- Question Source: Another student
--
-- Original Question:
-- Which tables contain a column named ProductID, according to the INFORMATION_SCHEMA.COLUMNS view?
--
-- A7:
-- This query searches INFORMATION_SCHEMA.COLUMNS for ProductID
-- and returns only user tables containing that column, excluding views.
-- ===============================================================================================================

SELECT DISTINCT
       TABLE_SCHEMA AS SchemaName,
       TABLE_NAME AS TableName
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME = 'ProductID'
  AND OBJECTPROPERTY
      (
          OBJECT_ID
          (
              QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
          ),
          'IsUserTable'
      ) = 1
ORDER BY
       TABLE_SCHEMA,
       TABLE_NAME;
GO

-- ===============================================================================================================
-- Q8 METADATA QUESTION
-- Original Author: Rodrigue Kpelly
-- Question Source: Another student
--
-- Original Question:
-- Which AdventureWorks tables belong to the Sales schema,
-- according to INFORMATION_SCHEMA.TABLES?
--
-- A8:
-- This query retrieves all base tables belonging to the Sales schema
-- from the INFORMATION_SCHEMA.TABLES metadata view.
-- ===============================================================================================================

SELECT
       TABLE_SCHEMA AS SchemaName,
       TABLE_NAME AS TableName,
       TABLE_TYPE AS TableType
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Sales'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY
       TABLE_NAME;
GO
