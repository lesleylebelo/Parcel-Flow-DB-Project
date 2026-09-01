/* 
   ParcelFlow — Courier Operations Database
   02_create_tables.sql
   A normalised operational schema (3NF) — customers, distribution
   centres, service types, parcels and a full status-change history
   rather than a single overwritten status column.
*/

USE ParcelFlowDB;
GO

CREATE TABLE dbo.DistributionCentres (
    CentreCode      CHAR(3)      PRIMARY KEY,
    CentreName      VARCHAR(50)  NOT NULL,
    Province        VARCHAR(50)  NOT NULL
);
GO

CREATE TABLE dbo.ServiceTypes (
    ServiceID       INT          IDENTITY(1,1) PRIMARY KEY,
    ServiceName     VARCHAR(30)  NOT NULL UNIQUE,
    MaxWeightKG     DECIMAL(8,2) NOT NULL,
    BaseFee         DECIMAL(10,2) NOT NULL
);
GO

CREATE TABLE dbo.Customers (
    CustomerID      INT          IDENTITY(1,1) PRIMARY KEY,
    CustomerName    VARCHAR(100) NOT NULL,
    Email           VARCHAR(100) NULL,
    Phone           VARCHAR(20)  NULL,
    City            VARCHAR(50)  NOT NULL
);
GO

CREATE TABLE dbo.Parcels (
    ParcelID            INT           IDENTITY(1001,1) PRIMARY KEY,
    CustomerID          INT           NOT NULL REFERENCES dbo.Customers(CustomerID),
    ServiceID           INT           NOT NULL REFERENCES dbo.ServiceTypes(ServiceID),
    DistributionCentre  CHAR(3)       NOT NULL REFERENCES dbo.DistributionCentres(CentreCode),
    Origin              VARCHAR(50)   NOT NULL,
    Destination         VARCHAR(50)   NOT NULL,
    Weight              DECIMAL(8,2)  NOT NULL,
    DeliveryFee         DECIMAL(10,2) NOT NULL,
    DispatchDate        DATE          NOT NULL,
    DeliveryDate        DATE          NULL,
    CurrentStatus       VARCHAR(20)   NOT NULL
        CONSTRAINT CK_Parcels_Status CHECK (CurrentStatus IN ('Delivered','In Transit','Delayed'))
);
GO

-- Full audit trail of every status change a parcel goes through,
-- instead of only ever seeing the latest value.
CREATE TABLE dbo.ParcelStatusHistory (
    HistoryID       INT           IDENTITY(1,1) PRIMARY KEY,
    ParcelID        INT           NOT NULL REFERENCES dbo.Parcels(ParcelID),
    Status          VARCHAR(20)   NOT NULL,
    ChangedAt       DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    ChangedBy       VARCHAR(50)   NULL
);
GO

-- Keep ParcelStatusHistory in sync automatically whenever a parcel's
-- status changes, so the audit trail never has to be maintained by hand.
CREATE TRIGGER dbo.trg_Parcels_StatusHistory
ON dbo.Parcels
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(CurrentStatus)
    BEGIN
        INSERT INTO dbo.ParcelStatusHistory (ParcelID, Status, ChangedBy)
        SELECT i.ParcelID, i.CurrentStatus, SUSER_SNAME()
        FROM inserted i
        JOIN deleted d ON i.ParcelID = d.ParcelID
        WHERE i.CurrentStatus <> d.CurrentStatus;
    END
END;
GO
