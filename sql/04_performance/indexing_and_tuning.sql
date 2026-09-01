/* 
   ParcelFlow — Query Performance & Indexing
   With 1,500+ rows this dataset is large enough for the optimiser
   to meaningfully choose between a scan and a seek — unlike a
   30-row table, where SQL Server will usually just scan regardless
   of which indexes exist.
*/

USE ParcelFlowDB;
GO

-- 1. A common but non-sargable management query

-- BAD: wraps DispatchDate in a function, forcing a scan; SELECT *
-- pulls every column even though only a few are needed.
SELECT *
FROM dbo.Parcels
WHERE YEAR(DispatchDate) = 2026
  AND DistributionCentre = 'JHB'
  AND DeliveryFee > 250;
GO

-- 2. Rewritten, sargable version

SELECT ParcelID, CustomerID, DispatchDate, DeliveryFee, CurrentStatus
FROM dbo.Parcels
WHERE DispatchDate >= '2026-01-01' AND DispatchDate < '2027-01-01'
  AND DistributionCentre = 'JHB'
  AND DeliveryFee > 250;
GO

-- 3. Supporting covering index

CREATE NONCLUSTERED INDEX IX_Parcels_Centre_Dispatch_Fee
ON dbo.Parcels (DistributionCentre, DispatchDate, DeliveryFee)
INCLUDE (ParcelID, CustomerID, CurrentStatus);
GO

-- Turn on "Include Actual Execution Plan" (Ctrl+M) in SSMS, then
-- re-run query #2 above. At this row count you should see SQL Server
-- choose an Index Seek on IX_Parcels_Centre_Dispatch_Fee rather than
-- a full Clustered Index Scan — the payoff this same experiment
-- couldn't demonstrate on a 30-row table.

-- 4. Before/after comparison using STATISTICS IO and TIME

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Non-sargable version
SELECT * FROM dbo.Parcels
WHERE YEAR(DispatchDate) = 2026 AND DistributionCentre = 'JHB' AND DeliveryFee > 250;

-- Sargable + indexed version
SELECT ParcelID, CustomerID, DispatchDate, DeliveryFee, CurrentStatus
FROM dbo.Parcels
WHERE DispatchDate >= '2026-01-01' AND DispatchDate < '2027-01-01'
  AND DistributionCentre = 'JHB' AND DeliveryFee > 250;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
-- Compare "logical reads" in the Messages tab between the two runs.
