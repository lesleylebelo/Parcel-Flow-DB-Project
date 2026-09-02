# ParcelFlow.Web — Setup Guide

This is the Blazor Server web interface for the ParcelFlow database project. It gives you parcel tracking, full CRUD management, and a live BI dashboard on top of the `ParcelFlowDB` SQL Server database you already built.

## 1. Prerequisites

Install these once:

| Tool | Why | Link |
|---|---|---|
| **.NET 8 SDK** | Builds and runs the project | https://dotnet.microsoft.com/download/dotnet/8.0 |
| **SQL Server** (or SQL Server Express / a Docker container) | Hosts `ParcelFlowDB` — you already set this up for the SQL project | — |
| **VS Code** + **C# Dev Kit** extension | Editing and running the project | Extension ID: `ms-dotnettools.csdevkit` |

Verify the SDK installed correctly:

```bash
dotnet --version
```

You should see something like `8.0.x`. If the command isn't found, restart your terminal/VS Code after installing (PATH changes need a fresh shell).

## 2. Confirm the database already exists

This web app **does not create the database** — it expects `ParcelFlowDB` to already exist with the schema and data from the SQL project. Before running the app, make sure you've already executed, in order:

1. `sql/01_schema/01_create_database.sql`
2. `sql/01_schema/02_create_tables.sql`
3. `sql/02_data/03_seed_data.sql`

(You can skip `03_transactions` through `08_bi_olap` for the web app specifically — those are optional deep-dive scripts and not required for the CRUD/tracking/dashboard pages to work, though the dashboard's queries assume `dbo.Parcels`, `dbo.Customers`, `dbo.ServiceTypes`, and `dbo.DistributionCentres` are populated.)

Quick check — run this in SSMS or Azure Data Studio:

```sql
USE ParcelFlowDB;
SELECT COUNT(*) FROM dbo.Parcels;
```

If this returns `0` or errors, go back and run the schema/seed scripts first.

## 3. Set your connection string

Open `appsettings.json` and update the connection string to match your SQL Server setup:

```json
{
  "ConnectionStrings": {
    "ParcelFlowDb": "Server=localhost;Database=ParcelFlowDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

- **Local SQL Server / SSMS with Windows Authentication** (most common on Windows): the default above should work as-is.
- **SQL Server in Docker, or using SQL logins instead of Windows auth**, replace it with:
  ```
  Server=localhost,1433;Database=ParcelFlowDB;User Id=sa;Password=YourPassword;TrustServerCertificate=True;
  ```
- **Named instance** (e.g. SQL Server Express installed as `SQLEXPRESS`):
  ```
  Server=localhost\SQLEXPRESS;Database=ParcelFlowDB;Trusted_Connection=True;TrustServerCertificate=True;
  ```

## 4. Restore and run

From the `ParcelFlow.Web` folder:

```bash
cd ParcelFlow.Web
dotnet restore
dotnet run
```

The terminal will print something like:

```
Now listening on: https://localhost:7123
Now listening on: http://localhost:5123
```

Open that `https://` URL in your browser. On first run, your browser or .NET may prompt you to trust a local dev HTTPS certificate — accept it:

```bash
dotnet dev-certs https --trust
```

## 5. Running it from VS Code directly

1. Open the `ParcelFlow.Web` folder in VS Code (`File → Open Folder`).
2. Install the **C# Dev Kit** extension if prompted (VS Code usually detects the `.csproj` and suggests it).
3. Press **F5** (or Run → Start Debugging). VS Code will build the project and launch it with the debugger attached, opening your browser automatically.
4. Set breakpoints directly in `.razor` or `.cs` files if you want to step through, e.g., `ParcelService.cs` or `DashboardService.cs`.

## 6. What you should see

- **Home (`/`)** — landing page with links to the three sections
- **Track a Parcel (`/track`)** — enter a Parcel ID (try one from your seed data, e.g. `1050`) to see its details and status history
- **Manage Parcels (`/parcels`)** — a live list with Add/Edit/Delete; editing a parcel's status automatically triggers `dbo.trg_Parcels_StatusHistory` on the database, so the history table fills in without any extra app code
- **Dashboard (`/dashboard`)** — a bar chart of revenue by centre, a pie chart of status breakdown, and a table drilling down by centre + service type

## 7. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `A network-related or instance-specific error...` on startup | SQL Server isn't running, or the `Server=` value in the connection string doesn't match your instance name. Confirm you can connect with the same details in SSMS first. |
| `Login failed for user 'sa'` | Wrong password, or SQL Server is set to Windows Authentication only — switch back to `Trusted_Connection=True` instead of a SQL login. |
| Blank dashboard / charts don't render | Check the browser console (F12) for JS errors — usually means `dbo.Parcels` has no rows yet (re-check step 2), or the CDN for Chart.js was blocked by your network. |
| `dotnet: command not found` | .NET SDK not installed or terminal wasn't restarted after install. |
| Certificate warnings in browser | Run `dotnet dev-certs https --trust` and restart the browser. |
| Build errors mentioning `Microsoft.Data.SqlClient` or `Dapper` not found | Run `dotnet restore` again — it needs internet access to pull NuGet packages the first time. |

## 8. Project structure recap

```
ParcelFlow.Web/
  Data/
    Models/Models.cs          entity classes + dashboard DTOs
    ParcelFlowDbContext.cs    EF Core mapping to the existing schema
    ParcelService.cs          CRUD + tracking queries (EF Core)
    DashboardService.cs       BI aggregation queries (Dapper)
  Pages/
    Home.razor
    Track.razor
    Parcels.razor
    Dashboard.razor
    _Host.cshtml
    Error.razor
  Shared/
    MainLayout.razor
  wwwroot/
    css/site.css
    js/charts.js
  Program.cs
  appsettings.json
```
