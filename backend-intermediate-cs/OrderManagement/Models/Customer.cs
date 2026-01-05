using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace OrderManagement.Models {
  [Table("customer")]
  public class Customer {
    [Key]
    [Column("customer_id")]
    public int CustomerId { get; set; }
    
    [Required]
    [Column("tax_id")]
    public string TaxId { get; set; } = string.Empty;
    
    [Required]
    [Column("first_name")]
    [RegularExpression(@"^[a-zA-ZÀ-ÿ\s]+$", ErrorMessage = "First name can only contain letters and spaces")]
    public string FirstName { get; set; } = string.Empty;
    
    [Required]
    [Column("last_name")]
    [RegularExpression(@"^[a-zA-ZÀ-ÿ\s]+$", ErrorMessage = "Last name can only contain letters and spaces")]
    public string LastName { get; set; } = string.Empty;
    
    [Column("identity_document")]
    public string? IdentityDocument { get; set; }
    
    [Column("phone")]
    [RegularExpression(@"^\+?[1-9]\d{1,14}$", ErrorMessage = "Invalid phone number format")]
    public string? Phone { get; set; }
    
    [Required]
    [Column("email")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [Column("address")]
    public string Address { get; set; } = string.Empty;
    
    [Required]
    [Column("city")]
    public string City { get; set; } = string.Empty;
    
    [Required]
    [Column("state")]
    public string State { get; set; } = string.Empty;
    
    [Required]
    [Column("postal_code")]
    [RegularExpression(@"^[0-9A-Za-z\s-]+$", ErrorMessage = "Invalid postal code format")]
    public string PostalCode { get; set; } = string.Empty;
  }
}
