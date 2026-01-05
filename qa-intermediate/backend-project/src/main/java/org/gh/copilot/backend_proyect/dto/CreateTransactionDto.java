package org.gh.copilot.backend_proyect.dto;

import jakarta.validation.constraints.*;
import lombok.Data;
import org.gh.copilot.backend_proyect.model.TransactionType;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * DTO para crear una nueva transacción.
 */
@Data
public class CreateTransactionDto {
    
    @NotBlank(message = "El ID de cuenta es obligatorio")
    private String accountId;
    
    @NotNull(message = "La fecha de transacción es obligatoria")
    private Instant postedAt;
    
    @NotNull(message = "El monto es obligatorio")
    @DecimalMin(value = "0.01", message = "El monto debe ser mayor a 0")
    private BigDecimal amount;
    
    @NotNull(message = "El tipo de transacción es obligatorio")
    private TransactionType type;
    
    @NotBlank(message = "La moneda es obligatoria")
    @Size(min = 3, max = 3, message = "La moneda debe tener exactamente 3 caracteres")
    private String currency;
    
    @NotBlank(message = "La descripción es obligatoria")
    @Size(max = 500, message = "La descripción no puede exceder los 500 caracteres")
    private String description;
    
    private Long categoryId;
}