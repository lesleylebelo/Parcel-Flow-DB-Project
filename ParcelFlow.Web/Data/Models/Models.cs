namespace ParcelFlow.Web.Data.Models;

public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; } = "";
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string City { get; set; } = "";
}

public class ServiceType
{
    public int ServiceID { get; set; }
    public string ServiceName { get; set; } = "";
    public decimal MaxWeightKG { get; set; }
    public decimal BaseFee { get; set; }
}

public class DistributionCentre
{
    public string CentreCode { get; set; } = ""; // JHB / CPT / DBN
    public string CentreName { get; set; } = "";
    public string Province { get; set; } = "";
}

public class Parcel
{
    public int ParcelID { get; set; }
    public int CustomerID { get; set; }
    public int ServiceID { get; set; }
    public string DistributionCentre { get; set; } = "";
    public string Origin { get; set; } = "";
    public string Destination { get; set; } = "";
    public decimal Weight { get; set; }
    public decimal DeliveryFee { get; set; }
    public DateTime DispatchDate { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string CurrentStatus { get; set; } = "In Transit";

    // Navigation properties (read-only convenience, not required for EF to function)
    public Customer? Customer { get; set; }
    public ServiceType? ServiceType { get; set; }
}

public class ParcelStatusHistory
{
    public int HistoryID { get; set; }
    public int ParcelID { get; set; }
    public string Status { get; set; } = "";
    public DateTime ChangedAt { get; set; }
    public string? ChangedBy { get; set; }
}

// Simple DTOs used by the dashboard/BI queries (not mapped tables)
public class CentreRevenue
{
    public string CentreName { get; set; } = "";
    public int NumberOfParcels { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AverageFee { get; set; }
}

public class CentreServiceRevenue
{
    public string CentreName { get; set; } = "";
    public string ServiceName { get; set; } = "";
    public int NumberOfParcels { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class StatusBreakdown
{
    public string Status { get; set; } = "";
    public int Count { get; set; }
}
