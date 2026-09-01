# ParcelFlow — Courier Operations Database

A SQL Server project simulating the operational database of a multi-region courier company, built to explore how a database designed for a single site evolves to support **concurrent access, query performance tuning, geographic data distribution, replication, and business intelligence** as an organisation grows.

The scenario: a fictional South African courier operating three regional distribution centres (Johannesburg, Cape Town, Durban) that has outgrown a simple single-table design and needs its data layer re-engineered to keep up.

## Why this project

Most database tutorials either stay purely theoretical or use datasets too small to show *why* techniques like indexing or fragmentation actually matter. This project generates a realistically-sized synthetic dataset (1,500+ parcels, 400 customers, spread across a 12-month window) specifically so that:

- indexing experiments show a genuine seek-vs-scan difference in the execution plan,
- fragmentation and replication checks operate on data volumes worth verifying programmatically rather than eyeballing,
- the BI layer produces analysis results that look like something a manager would actually want to see.

## What's inside

```
sql/
  01_schema/                    normalised 3NF schema, constraints, audit trigger
  02_data/                      Python-based synthetic data generator (seeded, reproducible)
  03_transactions/              COMMIT/ROLLBACK, concurrent-write locking, TRY/CATCH pattern
  04_performance/               sargable query rewrites, covering indexes, execution-plan analysis
  05_fragmentation/             horizontal fragmentation across 3 regional schemas + integrity checks
  06_replication/               cross-site replication, automated drift detection, transparency view
  07_distributed_transactions/  atomic multi-site parcel transfer with rollback-on-failure
  08_bi_olap/                   star schema + roll-up / drill-down / slice / pivot queries
diagrams/
  er-diagram.md                 Mermaid ER diagrams (operational schema + star schema)
docs/
  concepts-demonstrated.md      map of DB concepts to files, with rationale
.github/workflows/
  validate-sql.yml              CI: spins up a real SQL Server container and runs every script
```

See [`sql/00_run_all_in_order.md`](sql/00_run_all_in_order.md) for the exact execution sequence.

## Getting started

**Requirements:** SQL Server (2019+ or SQL Server Express) or a `mcr.microsoft.com/mssql/server` Docker container, plus Python 3 with `faker` if you want to regenerate the dataset.

```bash
# 1. Generate the seed data (or use the committed version in sql/02_data/03_seed_data.sql)
pip install faker
python sql/02_data/generate_data.py > sql/02_data/03_seed_data.sql

# 2. Run each script in SSMS, Azure Data Studio, or sqlcmd, in the order listed
#    in sql/00_run_all_in_order.md
```

## Key design decisions

- **Normalised operational schema, not a flat table.** Customers, service types, and distribution centres are separate reference tables; parcel status changes are captured in a full history table via trigger, not overwritten in place.
- **Data volume chosen deliberately.** 1,500 rows is small enough to run entirely on a laptop, but large enough that SQL Server's optimiser makes genuinely different choices depending on query shape and available indexes — the whole point of the performance section.
- **Fragmentation and replication implemented as separate schemas within one database**, which keeps the project runnable without provisioning multiple physical servers, while still correctly modelling the logical behaviour (transparency, distributed transactions, replica drift) that a true multi-server deployment would exhibit.

## Concepts demonstrated

See [`docs/concepts-demonstrated.md`](docs/concepts-demonstrated.md) for the full breakdown of database concepts covered and where to find each one.

## License

MIT — see [`LICENSE`](LICENSE).
