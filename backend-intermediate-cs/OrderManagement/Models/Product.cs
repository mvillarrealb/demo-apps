using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace OrderManagement.Models {
  [Table("product")]
  public class Product {
    [Key]
    [Column("product_id")]
    public int ProductId { get; set; }
    
    [Required]
    [Column("product_name")]
    public string ProductName { get; set; } = string.Empty;
    
    [Required]
    [Column("price")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0")]
    public double Price { get; set; }
    
    [Required]
    [Column("category_id")]
    [Range(1, int.MaxValue, ErrorMessage = "Category ID must be greater than 0")]
    public int CategoryId { get; set; }
    
    // Navigation property
    public virtual Category? Category { get; set; }
  }
}
