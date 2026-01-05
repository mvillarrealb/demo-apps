package org.gh.copilot.backend_proyect.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

/**
 * Configuración de CORS para la aplicación.
 * Lee los orígenes permitidos desde application.yaml
 */
@Configuration
@ConfigurationProperties(prefix = "cors")
@Data
public class CorsConfig implements WebMvcConfigurer {

    private List<String> allowedOrigins;
    private List<String> allowedMethods;
    private List<String> allowedHeaders;
    private boolean allowCredentials;
    private long maxAge;
    
    /**
     * Configura CORS para toda la aplicación basado en las propiedades del application.yaml.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // Configurar orígenes permitidos desde application.yaml
        if (allowedOrigins != null && !allowedOrigins.isEmpty()) {
            configuration.setAllowedOrigins(allowedOrigins);
        }
        
        // Configurar métodos HTTP permitidos
        if (allowedMethods != null && !allowedMethods.isEmpty()) {
            configuration.setAllowedMethods(allowedMethods);
        }
        
        // Configurar headers permitidos
        if (allowedHeaders != null && !allowedHeaders.isEmpty()) {
            configuration.setAllowedHeaders(allowedHeaders);
        }
        
        // Configurar si se permiten credenciales
        configuration.setAllowCredentials(allowCredentials);
        
        // Configurar tiempo de cache para preflight requests
        configuration.setMaxAge(maxAge);
        
        // Aplicar la configuración a todas las rutas
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        
        return source;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
            .allowedOrigins(allowedOrigins != null ? allowedOrigins.toArray(new String[0]) : new String[0])
            .allowedMethods(allowedMethods != null ? allowedMethods.toArray(new String[0]) : new String[0])
            .allowedHeaders(allowedHeaders != null ? allowedHeaders.toArray(new String[0]) : new String[0])
            .allowCredentials(allowCredentials)
            .maxAge(maxAge);
    }
}