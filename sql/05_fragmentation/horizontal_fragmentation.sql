/* 
   ParcelFlow — Horizontal Fragmentation
   Splits the Parcels table by DistributionCentre into three
   regional schemas, simulating three geographically distributed
   sites (JHB, CPT, DBN).
  */

USE ParcelFlowDB;
GO

CREATE SCHEMA JHB;
GO
CREATE SCHEMA CPT;
GO
CREATE SCHEMA DBN;
GO

CREATE TABLE JHB.Parcels (
    ParcelID INT PRIMARY KEY, CustomerID INT NOT NULL, ServiceID INT NOT NULL,
    DistributionCentre CHAR(3) NOT NULL, Origin VARCHAR(50) NOT NULL, Destination VARCHAR(50) NOT NULL,
    Weight DECIMAL(8,2) NOT NULL, DeliveryFee DECIMAL(10,2) NOT NULL,
    DispatchDate DATE NOT NULL, DeliveryDate DATE NULL, CurrentStatus VARCHAR(20) NOT NULL
);
GO
CREATE TABLE CPT.Parcels (
    ParcelID INT PRIMARY KEY, CustomerID INT NOT NULL, ServiceID INT NOT NULL,
    DistributionCentre CHAR(3) NOT NULL, Origin VARCHAR(50) NOT NULL, Destination VARCHAR(50) NOT NULL,
    Weight DECIMAL(8,2) NOT NULL, DeliveryFee DECIMAL(10,2) NOT NULL,
    DispatchDate DATE NOT NULL, DeliveryDate DATE NULL, CurrentStatus VARCHAR(20) NOT NULL
);
GO
CREATE TABLE DBN.Parcels (
    ParcelID INT PRIMARY KEY, CustomerID INT NOT NULL, ServiceID INT NOT NULL,
    DistributionCentre CHAR(3) NOT NULL, Origin VARCHAR(50) NOT NULL, Destination VARCHAR(50) NOT NULL,
    Weight DECIMAL(8,2) NOT NULL, DeliveryFee DECIMAL(10,2) NOT NULL,
    DispatchDate DATE NOT NULL, DeliveryDate DATE NULL, CurrentStatus VARCHAR(20) NOT NULL
);
GO

INSERT INTO JHB.Parcels SELECT ParcelID, CustomerID, ServiceID, DistributionCentre, Origin, Destination, Weight, DeliveryFee, DispatchDate, DeliveryDate, CurrentStatus FROM dbo.Parcels WHERE DistributionCentre = 'JHB';
INSERT INTO CPT.Parcels SELECT ParcelID, CustomerID, ServiceID, DistributionCentre, Origin, Destination, Weight, DeliveryFee, DispatchDate, DeliveryDate, CurrentStatus FROM dbo.Parcels WHERE DistributionCentre = 'CPT';
INSERT INTO DBN.Parcels SELECT ParcelID, CustomerID, ServiceID, DistributionCentre, Origin, Destination, Weight, DeliveryFee, DispatchDate, DeliveryDate, CurrentStatus FROM dbo.Parcels WHERE DistributionCentre = 'DBN';
GO

-- Fragmentation integrity checks

-- Missing from every fragment (expect 0 rows)
SELECT m.ParcelID FROM dbo.Parcels m
WHERE m.ParcelID NOT IN (
    SELECT ParcelID FROM JHB.Parcels
    UNION SELECT ParcelID FROM CPT.Parcels
    UNION SELECT ParcelID FROM DBN.Parcels
);

-- Present in more than one fragment (expect 0 rows)
SELECT ParcelID, COUNT(*) AS FragmentCount FROM (
    SELECT ParcelID FROM JHB.Parcels
    UNION ALL SELECT ParcelID FROM CPT.Parcels
    UNION ALL SELECT ParcelID FROM DBN.Parcels
) AS AllFragments
GROUP BY ParcelID HAVING COUNT(*) > 1;

-- Stored in the wrong regional fragment (expect 0 rows)
SELECT ParcelID, DistributionCentre, 'JHB' AS StoredIn FROM JHB.Parcels WHERE DistributionCentre <> 'JHB'
UNION
SELECT ParcelID, DistributionCentre, 'CPT' FROM CPT.Parcels WHERE DistributionCentre <> 'CPT'
UNION
SELECT ParcelID, DistributionCentre, 'DBN' FROM DBN.Parcels WHERE DistributionCentre <> 'DBN';
GO

/*
   Strategy: PRIMARY HORIZONTAL FRAGMENTATION — rows of a single base
   table are split by a selection predicate on one of its own
   attributes (DistributionCentre), each fragment keeping the full
   column set for a disjoint subset of rows.

   Allocation: PARTITIONED (non-replicated) — each fragment is
   stored at exactly one site, matched to the region that uses it.
*/
