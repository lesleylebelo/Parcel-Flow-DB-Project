using Dapper;
using Microsoft.Data.SqlClient;
using ParcelFlow.Web.Data.Models;

namespace ParcelFlow.Web.Data;

// Uses raw SQL via Dapper for the analytical queries, mirroring the
// roll-up / drill-down / slice logic in sql/08_bi_olap — this keeps the
// dashboard independent of whether the star schema has been deployed,
// by aggregating directly from the operational tables.
public class DashboardService
{
    private readonly string _connectionString;

    public DashboardService(IConfiguration config) =>
        _connectionString = config.GetConnectionString("ParcelFlowDb")
            ?? throw new InvalidOperationException("Connection string 'ParcelFlowDb' not found.");

    private SqlConnection CreateConnection() => new(_connectionString);

    // Roll-up: revenue summarised by distribution centre
    public async Task<List<CentreRevenue>> GetRevenueByCentreAsync()
    {
        const string sql = @"
            SELECT c.CentreName,
                   COUNT(*) AS NumberOfParcels,
                   SUM(p.DeliveryFee) AS TotalRevenue,
                   AVG(p.DeliveryFee) AS AverageFee
            FROM dbo.Parcels p
            JOIN dbo.DistributionCentres c ON p.DistributionCentre = c.CentreCode
            GROUP BY c.CentreName
            ORDER BY TotalRevenue DESC;";

        using var conn = CreateConnection();
        var result = await conn.QueryAsync<CentreRevenue>(sql);
        return result.ToList();
    }

    // Drill-down: revenue by centre AND service type
    public async Task<List<CentreServiceRevenue>> GetRevenueByCentreAndServiceAsync()
    {
        const string sql = @"
            SELECT c.CentreName, s.ServiceName,
                   COUNT(*) AS NumberOfParcels,
                   SUM(p.DeliveryFee) AS TotalRevenue
            FROM dbo.Parcels p
            JOIN dbo.DistributionCentres c ON p.DistributionCentre = c.CentreCode
            JOIN dbo.ServiceTypes s ON p.ServiceID = s.ServiceID
            GROUP BY c.CentreName, s.ServiceName
            ORDER BY TotalRevenue DESC;";

        using var conn = CreateConnection();
        var result = await conn.QueryAsync<CentreServiceRevenue>(sql);
        return result.ToList();
    }

    // Status breakdown across all parcels (Delivered / In Transit / Delayed)
    public async Task<List<StatusBreakdown>> GetStatusBreakdownAsync()
    {
        const string sql = @"
            SELECT CurrentStatus AS Status, COUNT(*) AS Count
            FROM dbo.Parcels
            GROUP BY CurrentStatus;";

        using var conn = CreateConnection();
        var result = await conn.QueryAsync<StatusBreakdown>(sql);
        return result.ToList();
    }

    // Slice: revenue by service type for a single named centre
    public async Task<List<CentreServiceRevenue>> GetRevenueForCentreAsync(string centreCode)
    {
        const string sql = @"
            SELECT c.CentreName, s.ServiceName,
                   COUNT(*) AS NumberOfParcels,
                   SUM(p.DeliveryFee) AS TotalRevenue
            FROM dbo.Parcels p
            JOIN dbo.DistributionCentres c ON p.DistributionCentre = c.CentreCode
            JOIN dbo.ServiceTypes s ON p.ServiceID = s.ServiceID
            WHERE p.DistributionCentre = @CentreCode
            GROUP BY c.CentreName, s.ServiceName;";

        using var conn = CreateConnection();
        var result = await conn.QueryAsync<CentreServiceRevenue>(sql, new { CentreCode = centreCode });
        return result.ToList();
    }
}
