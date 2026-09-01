/* 
   ParcelFlow — Replication & Consistency Checking
   Replicates the ServiceTypes reference table to all three regional
   sites (a natural candidate for replication since it changes
   rarely but is read constantly), then demonstrates detecting and
   correcting replica drift without eyeballing every table.
 */

USE ParcelFlowDB;
GO

CREATE TABLE JHB.ServiceTypes (ServiceID INT PRIMARY KEY, ServiceName VARCHAR(30), MaxWeightKG DECIMAL(8,2), BaseFee DECIMAL(10,2));
CREATE TABLE CPT.ServiceTypes (ServiceID INT PRIMARY KEY, ServiceName VARCHAR(30), MaxWeightKG DECIMAL(8,2), BaseFee DECIMAL(10,2));
CREATE TABLE DBN.ServiceTypes (ServiceID INT PRIMARY KEY, ServiceName VARCHAR(30), MaxWeightKG DECIMAL(8,2), BaseFee DECIMAL(10,2));
GO

INSERT INTO JHB.ServiceTypes SELECT * FROM dbo.ServiceTypes;
INSERT INTO CPT.ServiceTypes SELECT * FROM dbo.ServiceTypes;
INSERT INTO DBN.ServiceTypes SELECT * FROM dbo.ServiceTypes;
GO

-- Simulate drift: someone updates only the JHB replica
UPDATE JHB.ServiceTypes SET BaseFee = 290.00 WHERE ServiceName = 'Express';
GO

-- Automated inconsistency detection (no manual comparison required)
SELECT j.ServiceID, j.ServiceName,
       j.BaseFee AS JHB_Fee, c.BaseFee AS CPT_Fee, d.BaseFee AS DBN_Fee
FROM JHB.ServiceTypes j
JOIN CPT.ServiceTypes c ON j.ServiceID = c.ServiceID
JOIN DBN.ServiceTypes d ON j.ServiceID = d.ServiceID
WHERE j.BaseFee <> c.BaseFee OR j.BaseFee <> d.BaseFee;
GO

-- Correct the drift and re-verify (should return 0 rows)
UPDATE JHB.ServiceTypes SET BaseFee = 250.00 WHERE ServiceName = 'Express';
GO

SELECT j.ServiceID, j.ServiceName,
       j.BaseFee AS JHB_Fee, c.BaseFee AS CPT_Fee, d.BaseFee AS DBN_Fee
FROM JHB.ServiceTypes j
JOIN CPT.ServiceTypes c ON j.ServiceID = c.ServiceID
JOIN DBN.ServiceTypes d ON j.ServiceID = d.ServiceID
WHERE j.BaseFee <> c.BaseFee OR j.BaseFee <> d.BaseFee;
GO

-- Consolidated view for head-office access (fragmentation +
-- replication transparency: callers don't need to know the data
-- is split or where each fragment physically lives)

CREATE VIEW dbo.AllParcels AS
SELECT * FROM JHB.Parcels
UNION ALL
SELECT * FROM CPT.Parcels
UNION ALL
SELECT * FROM DBN.Parcels;
GO
