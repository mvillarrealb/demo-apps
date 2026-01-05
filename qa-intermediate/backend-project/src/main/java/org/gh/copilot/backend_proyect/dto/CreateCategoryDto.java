package org.gh.copilot.backend_proyect.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * DTO para crear una nueva categoría.
 */
@Data
public class CreateCategoryDto {
    
    @NotBlank(message = "El nombre de la categoría es obligatorio")
    @Size(max = 100, message = "El nombre no puede exceder los 100 caracteres")
    private String name;
    
    @Size(max = 7, message = "El color hex debe tener máximo 7 caracteres (incluyendo #)")
    private String colorHex;
}