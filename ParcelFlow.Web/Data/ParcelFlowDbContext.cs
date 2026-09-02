using Microsoft.EntityFrameworkCore;
using ParcelFlow.Web.Data.Models;

namespace ParcelFlow.Web.Data;

public class ParcelFlowDbContext : DbContext
{
    public ParcelFlowDbContext(DbContextOptions<ParcelFlowDbContext> options) : base(options) { }

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<ServiceType> ServiceTypes => Set<ServiceType>();
    public DbSet<DistributionCentre> DistributionCentres => Set<DistributionCentre>();
    public DbSet<Parcel> Parcels => Set<Parcel>();
    public DbSet<ParcelStatusHistory> ParcelStatusHistories => Set<ParcelStatusHistory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(e =>
        {
            e.ToTable("Customers", "dbo");
            e.HasKey(x => x.CustomerID);
            e.Property(x => x.CustomerID).ValueGeneratedOnAdd();
        });

        modelBuilder.Entity<ServiceType>(e =>
        {
            e.ToTable("ServiceTypes", "dbo");
            e.HasKey(x => x.ServiceID);
            e.Property(x => x.ServiceID).ValueGeneratedOnAdd();
        });

        modelBuilder.Entity<DistributionCentre>(e =>
        {
            e.ToTable("DistributionCentres", "dbo");
            e.HasKey(x => x.CentreCode);
            e.Property(x => x.CentreCode).HasMaxLength(3).IsFixedLength();
        });

        modelBuilder.Entity<Parcel>(e =>
        {
            e.ToTable("Parcels", "dbo");
            e.HasKey(x => x.ParcelID);
            e.Property(x => x.ParcelID).ValueGeneratedOnAdd();
            e.Property(x => x.DistributionCentre).HasMaxLength(3).IsFixedLength();

            e.HasOne(x => x.Customer)
                .WithMany()
                .HasForeignKey(x => x.CustomerID);

            e.HasOne(x => x.ServiceType)
                .WithMany()
                .HasForeignKey(x => x.ServiceID);
        });

        modelBuilder.Entity<ParcelStatusHistory>(e =>
        {
            e.ToTable("ParcelStatusHistory", "dbo");
            e.HasKey(x => x.HistoryID);
            e.Property(x => x.HistoryID).ValueGeneratedOnAdd();
        });
    }
}
