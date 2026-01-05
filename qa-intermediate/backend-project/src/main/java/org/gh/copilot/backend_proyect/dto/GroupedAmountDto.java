package org.gh.copilot.backend_proyect.dto;

import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO para respuesta de agregaciones agrupadas por categoría.
 * Representa el total agregado de transacciones por una clave específica.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class GroupedAmountDto {
    
    /**
     * Clave de agrupación (ej: nombre de categoría)
     */
    private String key;
    
    /**
     * Monto total neto (CREDIT suma positivo, DEBIT suma negativo)
     */
    private BigDecimal totalAmount;
    
    /**
     * Cantidad de transacciones en el grupo
     */
    private Long count;
    
    /**
     * Moneda de las transacciones
     */
    private String currency;
}