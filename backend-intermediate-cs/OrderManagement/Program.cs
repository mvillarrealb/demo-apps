using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;
using OrderManagement.Repositories;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Http.Json;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddDbContext<OrderContext>(opt => opt.UseNpgsql(builder.Configuration.GetConnectionString("OrderDatabase")));

// Register repositories
builder.Services.AddScoped<IRepository<Category, int>, CategoryRepository>();
builder.Services.AddScoped<IRepository<Customer, int>, CustomerRepository>();
builder.Services.AddScoped<IRepository<Order, int>, OrderRepository>();
builder.Services.AddScoped<IRepository<Product, int>, ProductRepository>();
builder.Services.AddScoped<IRepository<TodoItem, long>, TodoItemRepository>();
builder.Services.AddScoped<IRepository<Stock, int>, StockRepository>();
builder.Services.AddScoped<CustomerRepository>();
builder.Services.AddScoped<StockRepository>();
builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
});

var app = builder.Build();

app.UseCors(policy =>
    policy.AllowAnyOrigin()
          .AllowAnyMethod()
          .AllowAnyHeader());


// Use authorization middleware to enforce authentication and authorization policies on endpoints
app.UseAuthorization();
app.MapControllers();
app.Run();