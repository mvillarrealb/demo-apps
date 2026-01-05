using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace OrderManagement.Models {
    [Table("orders")]
    public class Order
    {
        [Key]
        [Column("order_number")]
        public int OrderNumber { get; set; }

        [Column("order_date")]
        [DataType(DataType.Date)]
        public DateOnly OrderDate { get; set; } = DateOnly.FromDateTime(DateTime.Now);
        
        [Column("total")]
        public double Total { get; set; }

        [Required]
        [Column("customer_id")]
        public int CustomerId { get; set; }

        // Navigation properties
        public Customer? Customer { get; set; }
        public ICollection<OrderDetail> Details { get; set; } = new List<OrderDetail>();
    }
}
