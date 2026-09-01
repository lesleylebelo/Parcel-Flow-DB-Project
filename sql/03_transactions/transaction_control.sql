/* 
   ParcelFlow — Transaction Management
   Demonstrates COMMIT/ROLLBACK semantics and row-level locking
   under concurrent access.
 */

USE ParcelFlowDB;
GO

-- 1. Basic COMMIT / ROLLBACK

-- Inspect a parcel before making any change
SELECT ParcelID, CurrentStatus FROM dbo.Parcels WHERE ParcelID = 1050;

BEGIN TRANSACTION;

UPDATE dbo.Parcels
SET CurrentStatus = 'In Transit'
WHERE ParcelID = 1050;

-- Uncommitted change is visible within this session...
SELECT ParcelID, CurrentStatus FROM dbo.Parcels WHERE ParcelID = 1050;

ROLLBACK TRANSACTION;

-- ...but is undone once rolled back. Demonstrates transaction atomicity:
-- changes are only durable once COMMIT is issued.
SELECT ParcelID, CurrentStatus FROM dbo.Parcels WHERE ParcelID = 1050;
GO

-- 2. Concurrency test (row-level exclusive locking)
--    Run "Window A" and "Window B" blocks below in two separate
--    SSMS query tabs connected to the same database.

-- WINDOW A — start a transaction and hold it open
BEGIN TRANSACTION;
UPDATE dbo.Parcels SET CurrentStatus = 'In Transit' WHERE ParcelID = 1051;
-- do not commit yet

-- WINDOW B — run this while Window A is still open; it will block
-- until Window A commits or rolls back
UPDATE dbo.Parcels SET CurrentStatus = 'Delivered' WHERE ParcelID = 1051;

-- Diagnose blocking sessions from a third window while B is waiting:
SELECT session_id, blocking_session_id, wait_type, wait_time
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

-- Back in Window A — release the lock
COMMIT TRANSACTION;
-- Window B immediately unblocks and completes
GO


-- 3. Safe pattern: TRY/CATCH transaction with automatic rollback
--    on failure — used throughout the distributed-transaction demo.


BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE dbo.Parcels SET CurrentStatus = 'Delayed' WHERE ParcelID = 1052;
    -- (a failing statement here would trigger the CATCH block below)

    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Transaction failed and was rolled back: ' + ERROR_MESSAGE();
END CATCH;
GO
