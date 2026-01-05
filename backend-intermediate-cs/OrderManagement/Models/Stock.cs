using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace OrderManagement.Models {
  [Table("stock")]
  public class Stock {
    [Key]
    [Column("stock_id")]
    public int StockId { get; set; }
    

    [Column("product_id")]
    public int ProductId { get; set; }
    
    [Required]
    [Column("quantity")]
    [Range(0, int.MaxValue, ErrorMessage = "Quantity must be at least 0")]
    public int Quantity { get; set; }
    
    [Column("created_at")]
    public DateTime CreatedAt { get; set; }
    
    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; }
    
    // Navigation property
    public virtual Product? Product { get; set; }
  }
}
