package org.gh.copilot.backend_proyect.exception;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.Map;

/**
 * Estructura estándar para respuestas de error de la API.
 */
@Data
@Builder
public class ErrorResponse {
    
    private Instant timestamp;
    private int status;
    private String error;
    private String message;
    private Map<String, String> details;
}