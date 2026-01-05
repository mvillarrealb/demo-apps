package org.gh.copilot.backend_proyect.dto;

import lombok.Data;

import java.time.Instant;

/**
 * DTO para respuesta de categoría.
 */
@Data
public class CategoryDto {
    
    private Long id;
    private String name;
    private String colorHex;
    private Instant createdAt;
}