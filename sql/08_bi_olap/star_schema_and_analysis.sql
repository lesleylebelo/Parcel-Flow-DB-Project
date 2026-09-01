/* 
   ParcelFlow — BI / OLAP Layer
   Builds a small star schema (fact + dimensions) on top of the
   operational data and runs the classic OLAP operations —
   roll-up, drill-down, and slice — against it.
*/

USE ParcelFlowDB;
GO

-- Dimension tables

CREATE TABLE dbo.DimDate (
    DateKey     INT PRIMARY KEY,      -- YYYYMMDD
    FullDate    DATE NOT NULL,
    Year        INT NOT NULL,
    Quarter     INT NOT NULL,
    MonthName   VARCHAR(10) NOT NULL,
    MonthNumber INT NOT NULL
);
GO

CREATE TABLE dbo.DimCentre (
    CentreCode  CHAR(3) PRIMARY KEY,
    CentreName  VARCHAR(50),
    Province    VARCHAR(50)
);
GO

CREATE TABLE dbo.DimServiceType (
    ServiceID   INT PRIMARY KEY,
    ServiceName VARCHAR(30)
);
GO

-- Fact table

CREATE TABLE dbo.FactParcelDeliveries (
    FactID        INT IDENTITY(1,1) PRIMARY KEY,
    ParcelID      INT NOT NULL,
    DateKey       INT NOT NULL REFERENCES dbo.DimDate(DateKey),
    CentreCode    CHAR(3) NOT NULL REFERENCES dbo.DimCentre(CentreCode),
    ServiceID     INT NOT NULL REFERENCES dbo.DimServiceType(ServiceID),
    DeliveryFee   DECIMAL(10,2) NOT NULL,
    Weight        DECIMAL(8,2) NOT NULL,
    IsDelivered   BIT NOT NULL
);
GO

-- ETL: populate dimensions and fact table from operational data

INSERT INTO dbo.DimDate (DateKey, FullDate, Year, Quarter, MonthName, MonthNumber)
SELECT DISTINCT
    CONVERT(INT, FORMAT(DispatchDate, 'yyyyMMdd')),
    DispatchDate,
    YEAR(DispatchDate),
    DATEPART(QUARTER, DispatchDate),
    DATENAME(MONTH, DispatchDate),
    MONTH(DispatchDate)
FROM dbo.Parcels;
GO

INSERT INTO dbo.DimCentre SELECT CentreCode, CentreName, Province FROM dbo.DistributionCentres;
INSERT INTO dbo.DimServiceType SELECT ServiceID, ServiceName FROM dbo.ServiceTypes;
GO

INSERT INTO dbo.FactParcelDeliveries (ParcelID, DateKey, CentreCode, ServiceID, DeliveryFee, Weight, IsDelivered)
SELECT
    ParcelID,
    CONVERT(INT, FORMAT(DispatchDate, 'yyyyMMdd')),
    DistributionCentre,
    ServiceID,
    DeliveryFee,
    Weight,
    CASE WHEN CurrentStatus = 'Delivered' THEN 1 ELSE 0 END
FROM dbo.Parcels;
GO

-- OLAP operation 1: ROLL-UP — revenue summarised to Centre level

SELECT c.CentreName,
       COUNT(*) AS NumberOfParcels,
       SUM(f.DeliveryFee) AS TotalRevenue,
       AVG(f.DeliveryFee) AS AvgFee
FROM dbo.FactParcelDeliveries f
JOIN dbo.DimCentre c ON f.CentreCode = c.CentreCode
GROUP BY c.CentreName;
GO

-- OLAP operation 2: DRILL-DOWN — Centre -> Centre + ServiceType

SELECT c.CentreName, s.ServiceName,
       COUNT(*) AS NumberOfParcels,
       SUM(f.DeliveryFee) AS TotalRevenue
FROM dbo.FactParcelDeliveries f
JOIN dbo.DimCentre c ON f.CentreCode = c.CentreCode
JOIN dbo.DimServiceType s ON f.ServiceID = s.ServiceID
GROUP BY c.CentreName, s.ServiceName
ORDER BY TotalRevenue DESC;
GO

-- OLAP operation 3: DRILL-DOWN further — Centre + ServiceType + Quarter--

SELECT c.CentreName, s.ServiceName, d.Year, d.Quarter,
       COUNT(*) AS NumberOfParcels,
       SUM(f.DeliveryFee) AS TotalRevenue
FROM dbo.FactParcelDeliveries f
JOIN dbo.DimCentre c ON f.CentreCode = c.CentreCode
JOIN dbo.DimServiceType s ON f.ServiceID = s.ServiceID
JOIN dbo.DimDate d ON f.DateKey = d.DateKey
GROUP BY c.CentreName, s.ServiceName, d.Year, d.Quarter
ORDER BY d.Year, d.Quarter, TotalRevenue DESC;
GO

-- OLAP operation 4: SLICE — fix Centre = Cape Town, analyse by ServiceType

SELECT s.ServiceName,
       COUNT(*) AS NumberOfParcels,
       SUM(f.DeliveryFee) AS TotalRevenue
FROM dbo.FactParcelDeliveries f
JOIN dbo.DimServiceType s ON f.ServiceID = s.ServiceID
JOIN dbo.DimCentre c ON f.CentreCode = c.CentreCode
WHERE c.CentreCode = 'CPT'
GROUP BY s.ServiceName;
GO

-- OLAP operation 5: PIVOT — Centres as columns, Quarters as rows

SELECT Quarter, [JHB], [CPT], [DBN]
FROM (
    SELECT d.Quarter, f.CentreCode, f.DeliveryFee
    FROM dbo.FactParcelDeliveries f
    JOIN dbo.DimDate d ON f.DateKey = d.DateKey
) AS SourceTable
PIVOT (
    SUM(DeliveryFee) FOR CentreCode IN ([JHB], [CPT], [DBN])
) AS PivotTable
ORDER BY Quarter;
GO
