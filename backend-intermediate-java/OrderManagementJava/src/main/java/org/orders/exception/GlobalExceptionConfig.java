package org.orders.exception;

import org.springframework.boot.autoconfigure.web.WebProperties;
import org.springframework.boot.autoconfigure.web.reactive.error.AbstractErrorWebExceptionHandler;
import org.springframework.boot.web.error.ErrorAttributeOptions;
import org.springframework.boot.web.reactive.error.ErrorAttributes;
import org.springframework.boot.web.reactive.error.DefaultErrorAttributes;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerCodecConfigurer;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebExchangeBindException;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Configuration
public class GlobalExceptionConfig {

    @Bean
    public WebProperties.Resources resources() {
        return new WebProperties.Resources();
    }

    @Bean
    public ErrorAttributes errorAttributes() {
        return new DefaultErrorAttributes();
    }

    @Component
    @Order(-2) // Alta prioridad para asegurar que se ejecute antes que otros manejadores
    public static class GlobalErrorWebExceptionHandler extends AbstractErrorWebExceptionHandler {

        public GlobalErrorWebExceptionHandler(ErrorAttributes errorAttributes,
                                             WebProperties.Resources resources,
                                             ApplicationContext applicationContext,
                                             ServerCodecConfigurer serverCodecConfigurer) {
            super(errorAttributes, resources, applicationContext);
            super.setMessageWriters(serverCodecConfigurer.getWriters());
            super.setMessageReaders(serverCodecConfigurer.getReaders());
        }

        @Override
        protected RouterFunction<ServerResponse> getRoutingFunction(ErrorAttributes errorAttributes) {
            return RouterFunctions.route(RequestPredicates.all(), this::renderErrorResponse);
        }

        private Mono<ServerResponse> renderErrorResponse(ServerRequest request) {
            Map<String, Object> errorPropertiesMap = getErrorAttributes(request, ErrorAttributeOptions.defaults());
            Throwable error = getError(request);

            if (error instanceof WebExchangeBindException validationException) {
                // Manejo de errores de validación
                String fieldErrors = validationException.getBindingResult()
                        .getFieldErrors()
                        .stream()
                        .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                        .collect(Collectors.joining(", "));

                ErrorResponse response = ErrorResponse.builder()
                        .code("400")
                        .message("Validation Error")
                        .description(fieldErrors)
                        .build();

                return ServerResponse.status(HttpStatus.BAD_REQUEST)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(BodyInserters.fromValue(response));
            }
            else if (error instanceof ResponseStatusException statusException) {
                // Manejo de errores de status HTTP
                HttpStatus status = HttpStatus.valueOf(statusException.getStatusCode().value());
                String code = String.valueOf(status.value());
                String message = status.getReasonPhrase();
                String description = statusException.getReason();

                ErrorResponse response = ErrorResponse.builder()
                        .code(code)
                        .message(message)
                        .description(description)
                        .build();

                return ServerResponse.status(status)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(BodyInserters.fromValue(response));
            }
            else if (error instanceof IllegalArgumentException) {
                // Manejo de errores de argumentos inválidos
                ErrorResponse response = ErrorResponse.builder()
                        .code("400")
                        .message("Invalid Argument")
                        .description(error.getMessage())
                        .build();

                return ServerResponse.status(HttpStatus.BAD_REQUEST)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(BodyInserters.fromValue(response));
            }
            else {
                // Manejo de errores genéricos
                HttpStatus status = HttpStatus.valueOf((Integer) errorPropertiesMap.get("status"));
                String code = String.valueOf(status.value());
                String message = status.getReasonPhrase();
                String description = Optional.ofNullable(error.getMessage())
                        .orElse("An unexpected error occurred");

                ErrorResponse response = ErrorResponse.builder()
                        .code(code)
                        .message(message)
                        .description(description)
                        .build();

                return ServerResponse.status(status)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(BodyInserters.fromValue(response));
            }
        }
    }
}
