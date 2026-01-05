package org.orders.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "customer")
@Getter
@Setter
public class Customer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "customer_id")
    private Integer customerId;

    @NotBlank
    @Column(name = "tax_id", nullable = false)
    private String taxId;

    @NotBlank
    @Pattern(regexp = "^[a-zA-ZÀ-ÿ\s]+$", message = "First name can only contain letters and spaces")
    @Column(name = "first_name", nullable = false)
    private String firstName;

    @NotBlank
    @Pattern(regexp = "^[a-zA-ZÀ-ÿ\s]+$", message = "Last name can only contain letters and spaces")
    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(name = "identity_document")
    private String identityDocument;

    @Pattern(regexp = "^\\+?[1-9]\\d{1,14}$", message = "Invalid phone number format")
    @Column(name = "phone")
    private String phone;

    @NotBlank
    @Email(message = "Invalid email format")
    @Column(name = "email", nullable = false)
    private String email;

    @NotBlank
    @Column(name = "address", nullable = false)
    private String address;

    @NotBlank
    @Column(name = "city", nullable = false)
    private String city;

    @NotBlank
    @Column(name = "state", nullable = false)
    private String state;

    @NotBlank
    @Pattern(regexp = "^[0-9A-Za-z\s-]+$", message = "Invalid postal code format")
    @Column(name = "postal_code", nullable = false)
    private String postalCode;
}
