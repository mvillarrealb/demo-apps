package org.gh.copilot.backend_proyect.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.gh.copilot.backend_proyect.dto.CategoryDto;
import org.gh.copilot.backend_proyect.dto.CreateCategoryDto;
import org.gh.copilot.backend_proyect.service.CategoryService;

/**
 * Controlador REST para gestionar categorías de transacciones.
 */
@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {
    
    private final CategoryService categoryService;
    
    /**
     * Crea una nueva categoría.
     * POST /api/categories
     */
    @PostMapping
    public ResponseEntity<CategoryDto> create(@Valid @RequestBody CreateCategoryDto createCategoryDto) {
        CategoryDto createdCategory = categoryService.create(createCategoryDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdCategory);
    }
    
    /**
     * Obtiene una categoría por ID.
     * GET /api/categories/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<CategoryDto> getById(@PathVariable Long id) {
        CategoryDto category = categoryService.findById(id);
        return ResponseEntity.ok(category);
    }
    
    /**
     * Obtiene todas las categorías con filtros opcionales y paginación.
     * GET /api/categories?q=&page=&size=&sort=
     */
    @GetMapping
    public ResponseEntity<Page<CategoryDto>> getAll(
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "name,ASC") String sort) {
        
        Page<CategoryDto> categories = categoryService.findAll(q, page, size, sort);
        return ResponseEntity.ok(categories);
    }
}