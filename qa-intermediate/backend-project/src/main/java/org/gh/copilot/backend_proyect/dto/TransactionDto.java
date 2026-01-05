package org.gh.copilot.backend_proyect.dto;

import lombok.Data;
import org.gh.copilot.backend_proyect.model.TransactionType;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * DTO para respuesta de transacción.
 */
@Data
public class TransactionDto {
    
    private Long id;
    private String accountId;
    private Instant postedAt;
    private BigDecimal amount;
    private TransactionType type;
    private String currency;
    private String description;
    private Long categoryId;
    private CategoryDto category;
    private Instant createdAt;
}