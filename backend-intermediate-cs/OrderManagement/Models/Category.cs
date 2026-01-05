using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace OrderManagement.Models {
  [Table("category")]
  public class Category {
    [Key]
    [Column("category_id")]
    public int CategoryId { get; set; }
    
    [Required]
    [Column("category_name")]
    [RegularExpression(@"^[a-zA-ZÀ-ÿ0-9\s&-]+$", ErrorMessage = "Category name can only contain letters, numbers, spaces, & and - characters")]
    public string CategoryName { get; set; } = string.Empty;
  }
}
