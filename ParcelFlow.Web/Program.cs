using Microsoft.EntityFrameworkCore;
using ParcelFlow.Web.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

builder.Services.AddDbContext<ParcelFlowDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ParcelFlowDb")));

builder.Services.AddScoped<ParcelService>();
builder.Services.AddScoped<DashboardService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
