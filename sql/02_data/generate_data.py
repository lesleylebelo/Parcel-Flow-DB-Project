"""
ParcelFlow — synthetic data generator

Generates a realistically-sized dataset (not just 30 rows) so that
downstream indexing/performance experiments actually have enough
volume for SQL Server's optimiser to choose an index seek over a
scan. Produces reference data plus ~1,500 parcels spread across
three regional distribution centres and twelve months.

Usage:
    python generate_data.py > 03_seed_data.sql
"""

import random
from datetime import date, timedelta

random.seed(42)  # reproducible output

CENTRES = {
    "JHB": {"name": "Johannesburg", "province": "Gauteng",
            "cities": ["Johannesburg", "Pretoria", "Midrand", "Vereeniging", "Rustenburg", "Polokwane"]},
    "CPT": {"name": "Cape Town", "province": "Western Cape",
            "cities": ["Cape Town", "Stellenbosch", "Paarl", "George", "Worcester", "Hermanus"]},
    "DBN": {"name": "Durban", "province": "KwaZulu-Natal",
            "cities": ["Durban", "Pietermaritzburg", "Richards Bay", "Umhlanga", "Ballito", "Newcastle"]},
}

SERVICE_TYPES = [
    ("Standard", 20.00, 150.00),
    ("Express", 15.00, 250.00),
    ("Same Day", 10.00, 320.00),
]

FIRST_NAMES = ["Thabo", "Naledi", "Sipho", "Lerato", "Kagiso", "Ayanda", "Mpho", "Karabo",
               "Tshepo", "Boitumelo", "Anathi", "Lwazi", "Zanele", "Siyabonga", "Amahle",
               "Sibusiso", "Nokuthula", "Bongani", "Thandiwe", "Mandla", "Nhlanhla", "Palesa",
               "Bhekisisa", "Nosipho", "Refilwe", "Katlego", "Zinhle", "Sizwe", "Nomvula", "Mmabatho"]
SURNAMES = ["Mokoena", "Khumalo", "Dlamini", "Molefe", "Ndlovu", "Zulu", "Nkosi", "Maseko",
            "Sithole", "Jacobs", "Daniels", "Adams", "Williams", "Petersen", "Brown", "Smith",
            "Davids", "Jones", "September", "Cele", "Mbatha", "Nxumalo", "Mahlangu", "Radebe"]

STATUS_WEIGHTS = [("Delivered", 0.70), ("In Transit", 0.20), ("Delayed", 0.10)]


def weighted_status():
    r = random.random()
    cumulative = 0
    for status, weight in STATUS_WEIGHTS:
        cumulative += weight
        if r <= cumulative:
            return status
    return "Delivered"


def sql_escape(text):
    return text.replace("'", "''")


def generate():
    lines = []

    # ---- Reference data ----
    lines.append("USE ParcelFlowDB;")
    lines.append("GO\n")

    lines.append("INSERT INTO dbo.DistributionCentres (CentreCode, CentreName, Province) VALUES")
    centre_rows = [f"('{code}', '{v['name']}', '{v['province']}')" for code, v in CENTRES.items()]
    lines.append(",\n".join(centre_rows) + ";")
    lines.append("GO\n")

    lines.append("INSERT INTO dbo.ServiceTypes (ServiceName, MaxWeightKG, BaseFee) VALUES")
    service_rows = [f"('{n}', {w}, {f})" for n, w, f in SERVICE_TYPES]
    lines.append(",\n".join(service_rows) + ";")
    lines.append("GO\n")

    # ---- Customers ----
    num_customers = 400
    customers = []
    for i in range(num_customers):
        name = f"{random.choice(FIRST_NAMES)} {random.choice(SURNAMES)}"
        centre = random.choice(list(CENTRES.keys()))
        city = random.choice(CENTRES[centre]["cities"])
        email = f"{name.lower().replace(' ', '.')}{i}@example.co.za"
        phone = f"0{random.randint(60,89)}{random.randint(1000000,9999999)}"
        customers.append((name, email, phone, city))

    lines.append("INSERT INTO dbo.Customers (CustomerName, Email, Phone, City) VALUES")
    cust_rows = [f"('{sql_escape(n)}', '{e}', '{p}', '{sql_escape(c)}')" for n, e, p, c in customers]
    # Batch inserts of 200 rows to stay within SQL Server's row-constructor limit
    for batch_start in range(0, len(cust_rows), 200):
        batch = cust_rows[batch_start:batch_start + 200]
        lines.append(",\n".join(batch) + (";" if batch_start + 200 >= len(cust_rows) else ";\nINSERT INTO dbo.Customers (CustomerName, Email, Phone, City) VALUES"))
    lines.append("GO\n")

    # ---- Parcels across a 12-month window ----
    num_parcels = 1500
    start_date = date(2025, 9, 1)
    end_date = date(2026, 8, 31)
    date_span = (end_date - start_date).days

    parcel_rows = []
    parcel_id_counter = 1001  # matches IDENTITY seed
    for _ in range(num_parcels):
        centre = random.choices(list(CENTRES.keys()), weights=[0.38, 0.34, 0.28])[0]
        origin = random.choice(CENTRES[centre]["cities"])
        destination = random.choice(CENTRES[centre]["cities"])
        while destination == origin:
            destination = random.choice(CENTRES[centre]["cities"])
        service_idx = random.choices(range(3), weights=[0.5, 0.35, 0.15])[0]
        service_name, max_weight, base_fee = SERVICE_TYPES[service_idx]
        weight = round(random.uniform(0.5, max_weight), 2)
        fee_variance = round(random.uniform(-30, 80), 2)
        fee = round(base_fee + fee_variance, 2)
        dispatch = start_date + timedelta(days=random.randint(0, date_span))
        status = weighted_status()
        delivery = None
        if status == "Delivered":
            delivery = dispatch + timedelta(days=random.randint(0, 5))
        customer_idx = random.randint(1, num_customers)  # matches IDENTITY seed

        delivery_sql = f"'{delivery.isoformat()}'" if delivery else "NULL"
        parcel_rows.append(
            f"({customer_idx}, {service_idx + 1}, '{centre}', '{sql_escape(origin)}', "
            f"'{sql_escape(destination)}', {weight}, {fee}, '{dispatch.isoformat()}', "
            f"{delivery_sql}, '{status}')"
        )

    lines.append("INSERT INTO dbo.Parcels")
    lines.append("    (CustomerID, ServiceID, DistributionCentre, Origin, Destination,")
    lines.append("     Weight, DeliveryFee, DispatchDate, DeliveryDate, CurrentStatus)")
    lines.append("VALUES")
    for batch_start in range(0, len(parcel_rows), 200):
        batch = parcel_rows[batch_start:batch_start + 200]
        is_last = batch_start + 200 >= len(parcel_rows)
        lines.append(",\n".join(batch) + (";" if is_last else
            ";\nINSERT INTO dbo.Parcels\n    (CustomerID, ServiceID, DistributionCentre, Origin, Destination,\n     Weight, DeliveryFee, DispatchDate, DeliveryDate, CurrentStatus)\nVALUES"))
    lines.append("GO\n")

    lines.append("-- Sanity check: should show 1,500 parcels distributed across JHB/CPT/DBN")
    lines.append("SELECT DistributionCentre, COUNT(*) AS ParcelCount FROM dbo.Parcels GROUP BY DistributionCentre;")
    lines.append("GO")

    return "\n".join(lines)


if __name__ == "__main__":
    print(generate())
