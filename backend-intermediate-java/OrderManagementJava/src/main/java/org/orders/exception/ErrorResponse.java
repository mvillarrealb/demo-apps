package org.orders.exception;

public class ErrorResponse {
    private String code;
    private String message;
    private String description;

    // Constructor sin parámetros
    public ErrorResponse() {}

    // Constructor con parámetros
    public ErrorResponse(String code, String message, String description) {
        this.code = code;
        this.message = message;
        this.description = description;
    }

    // Getters y Setters
    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    // Método builder estático
    public static ErrorResponseBuilder builder() {
        return new ErrorResponseBuilder();
    }

    // Clase Builder interna
    public static class ErrorResponseBuilder {
        private String code;
        private String message;
        private String description;

        public ErrorResponseBuilder code(String code) {
            this.code = code;
            return this;
        }

        public ErrorResponseBuilder message(String message) {
            this.message = message;
            return this;
        }

        public ErrorResponseBuilder description(String description) {
            this.description = description;
            return this;
        }

        public ErrorResponse build() {
            return new ErrorResponse(this.code, this.message, this.description);
        }
    }
}

