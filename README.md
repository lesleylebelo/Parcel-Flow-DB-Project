# ParcelFlow — Courier Operations Database

A SQL Server project simulating the operational database of a multi-region courier company, built to explore how a database designed for a single site evolves to support **concurrent access, query performance tuning, geographic data distribution, replication, and business intelligence** as an organisation grows.

The scenario: a fictional South African courier operating three regional distribution centres (Johannesburg, Cape Town, Durban) that has outgrown a simple single-table design and needs its data layer re-engineered to keep up.

## Why this project

Most database tutorials either stay purely theoretical or use datasets too small to show *why* techniques like indexing or fragmentation actually matter. This project generates a realistically-sized synthetic dataset (1,500+ parcels, 400 customers, spread across a 12-month window) specifically so that:

- indexing experiments show a genuine seek-vs-scan difference in the execution plan,
- fragmentation and replication checks operate on data volumes worth verifying programmatically rather than eyeballing,
- the BI layer produces analysis results that look like something a manager would actually want to see.

