using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace OrderManagement.Models {
    [Table("order_detail")]
    public class OrderDetail
    {
        [Key]
        [Column("detail_id")]
        public int DetailId { get; set; }

        [Column("amount")]
        public double Amount { get; set; }

        [Required]
        [Column("quantity")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }

        [Required]
        [Column("order_number")]
        public int OrderNumber { get; set; }

        [Required]
        [Column("product_id")]
        public int ProductId { get; set; }
        [JsonIgnore]
        // Navigation properties
        public Order? Order { get; set; }
        
        public Product? Product { get; set; }
    }
}
