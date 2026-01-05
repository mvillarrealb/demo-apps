using Microsoft.EntityFrameworkCore;

namespace OrderManagement.Models {
  public class OrderContext : DbContext
  {
    public OrderContext(DbContextOptions<OrderContext> options)
        : base(options)
    {
    }
    public DbSet<TodoItem> TodoItems { get; set; } = null!;
    public DbSet<Category> Categories { get; set; } = null!;
    public DbSet<Product> Products { get; set; } = null!;
    public DbSet<Stock> Stocks { get; set; } = null!;
    public DbSet<Customer> Customers { get; set; } = null!;
    public DbSet<Order> Orders { get; set; } = null!;
    public DbSet<OrderDetail> OrderDetails { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure OrderDetail relationships
        modelBuilder.Entity<OrderDetail>()
            .HasOne(od => od.Order)
            .WithMany(o => o.Details)
            .HasForeignKey(od => od.OrderNumber)
            .HasPrincipalKey(o => o.OrderNumber);

        modelBuilder.Entity<OrderDetail>()
            .HasOne(od => od.Product)
            .WithMany()
            .HasForeignKey(od => od.ProductId);
    }
  }
}