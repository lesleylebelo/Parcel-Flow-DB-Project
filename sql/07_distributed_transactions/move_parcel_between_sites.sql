/* 
   ParcelFlow — Distributed Transaction
   Moves a misrouted parcel from one regional fragment to another
   as a single atomic operation spanning two sites.
*/

USE ParcelFlowDB;
GO

DECLARE @ParcelToMove INT = (SELECT TOP 1 ParcelID FROM JHB.Parcels ORDER BY ParcelID);

-- 1. Verify current location before changing anything
SELECT 'JHB' AS FoundIn, * FROM JHB.Parcels WHERE ParcelID = @ParcelToMove;
GO

-- 2. Move as a single atomic transaction across two sites (JHB + CPT)
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ParcelID INT = (SELECT TOP 1 ParcelID FROM JHB.Parcels ORDER BY ParcelID);

    INSERT INTO CPT.Parcels
    SELECT ParcelID, CustomerID, ServiceID, 'CPT', Origin, Destination,
           Weight, DeliveryFee, DispatchDate, DeliveryDate, CurrentStatus
    FROM JHB.Parcels WHERE ParcelID = @ParcelID;

    DELETE FROM JHB.Parcels WHERE ParcelID = @ParcelID;

    COMMIT TRANSACTION;
    PRINT 'Move committed successfully across JHB and CPT.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Move failed and was rolled back: ' + ERROR_MESSAGE();
END CATCH;
GO

-- 3. Verify the parcel now exists exactly once, in CPT
SELECT 'JHB' AS FoundIn FROM JHB.Parcels WHERE ParcelID = (SELECT MIN(ParcelID) FROM CPT.Parcels)
UNION ALL
SELECT 'CPT' FROM CPT.Parcels WHERE ParcelID = (SELECT MIN(ParcelID) FROM CPT.Parcels);
GO

/*
   Classification: DISTRIBUTED TRANSACTION, not a remote transaction.
   A remote transaction executes entirely at a single remote site;
   here, one atomic unit of work performs operations at two distinct
   sites (JHB and CPT), which is the defining trait of a distributed
   transaction.
*/
