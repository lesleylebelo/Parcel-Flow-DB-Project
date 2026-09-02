using Microsoft.EntityFrameworkCore;
using ParcelFlow.Web.Data.Models;

namespace ParcelFlow.Web.Data;

public class ParcelService
{
    private readonly ParcelFlowDbContext _db;

    public ParcelService(ParcelFlowDbContext db) => _db = db;

    public async Task<List<Parcel>> GetRecentParcelsAsync(int take = 100) =>
        await _db.Parcels
            .Include(p => p.Customer)
            .Include(p => p.ServiceType)
            .OrderByDescending(p => p.DispatchDate)
            .Take(take)
            .ToListAsync();

    public async Task<Parcel?> GetParcelAsync(int parcelId) =>
        await _db.Parcels
            .Include(p => p.Customer)
            .Include(p => p.ServiceType)
            .FirstOrDefaultAsync(p => p.ParcelID == parcelId);

    public async Task<List<ParcelStatusHistory>> GetStatusHistoryAsync(int parcelId) =>
        await _db.ParcelStatusHistories
            .Where(h => h.ParcelID == parcelId)
            .OrderBy(h => h.ChangedAt)
            .ToListAsync();

    public async Task<List<Customer>> GetCustomersAsync() =>
        await _db.Customers.OrderBy(c => c.CustomerName).ToListAsync();

    public async Task<List<ServiceType>> GetServiceTypesAsync() =>
        await _db.ServiceTypes.OrderBy(s => s.ServiceName).ToListAsync();

    public async Task<List<DistributionCentre>> GetCentresAsync() =>
        await _db.DistributionCentres.OrderBy(c => c.CentreName).ToListAsync();

    public async Task<Parcel> CreateParcelAsync(Parcel parcel)
    {
        _db.Parcels.Add(parcel);
        await _db.SaveChangesAsync();
        return parcel;
    }

    public async Task UpdateParcelAsync(Parcel parcel)
    {
        _db.Parcels.Update(parcel);
        await _db.SaveChangesAsync();
        // Note: the AFTER UPDATE trigger (trg_Parcels_StatusHistory) on the
        // database automatically records a ParcelStatusHistory row whenever
        // CurrentStatus changes — no application-level code needed for that.
    }

    public async Task DeleteParcelAsync(int parcelId)
    {
        // Remove dependent history rows first (no cascade delete configured
        // at the DB level, to avoid accidentally losing audit trail data
        // through an unrelated cascade elsewhere).
        var history = _db.ParcelStatusHistories.Where(h => h.ParcelID == parcelId);
        _db.ParcelStatusHistories.RemoveRange(history);

        var parcel = await _db.Parcels.FindAsync(parcelId);
        if (parcel != null) _db.Parcels.Remove(parcel);

        await _db.SaveChangesAsync();
    }
}
