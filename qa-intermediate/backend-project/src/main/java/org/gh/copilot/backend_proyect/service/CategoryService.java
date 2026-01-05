package org.gh.copilot.backend_proyect.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.gh.copilot.backend_proyect.dto.CategoryDto;
import org.gh.copilot.backend_proyect.dto.CreateCategoryDto;
import org.gh.copilot.backend_proyect.mapper.CategoryMapper;
import org.gh.copilot.backend_proyect.model.Category;
import org.gh.copilot.backend_proyect.repository.CategoryRepository;

import java.util.Set;

/**
 * Servicio para gestionar operaciones de negocio relacionadas con categorías.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {
    
    private final CategoryRepository categoryRepository;
    private final CategoryMapper categoryMapper;
    
    // Campos permitidos para ordenamiento
    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("name", "createdAt");
    
    /**
     * Crea una nueva categoría.
     */
    @Transactional
    public CategoryDto create(CreateCategoryDto createCategoryDto) {
        // Validar nombre único
        if (categoryRepository.existsByNameIgnoreCase(createCategoryDto.getName())) {
            throw new IllegalArgumentException("Ya existe una categoría con el nombre: " + createCategoryDto.getName());
        }
        
        Category category = categoryMapper.toEntity(createCategoryDto);
        Category savedCategory = categoryRepository.save(category);
        return categoryMapper.toDto(savedCategory);
    }
    
    /**
     * Busca una categoría por ID.
     */
    public CategoryDto findById(Long id) {
        Category category = categoryRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Categoría no encontrada con ID: " + id));
        return categoryMapper.toDto(category);
    }
    
    /**
     * Busca categorías con filtros y paginación.
     */
    public Page<CategoryDto> findAll(String q, int page, int size, String sort) {
        // Normalizar parámetros de paginación
        page = Math.max(0, page);
        size = Math.max(1, Math.min(100, size));
        
        // Validar y crear ordenamiento
        Sort sortObj = createSort(sort);
        
        Pageable pageable = PageRequest.of(page, size, sortObj);
        Page<Category> categories = categoryRepository.findAllWithFilters(q, pageable);
        
        return categories.map(categoryMapper::toDto);
    }
    
    /**
     * Crea objeto Sort validando los campos permitidos.
     */
    private Sort createSort(String sortParam) {
        if (sortParam == null || sortParam.trim().isEmpty()) {
            return Sort.by(Sort.Direction.ASC, "name"); // Default
        }
        
        String[] parts = sortParam.split(",");
        if (parts.length != 2) {
            return Sort.by(Sort.Direction.ASC, "name"); // Default
        }
        
        String field = parts[0].trim();
        String direction = parts[1].trim().toLowerCase();
        
        // Validar campo permitido
        if (!ALLOWED_SORT_FIELDS.contains(field)) {
            field = "name"; // Default
        }
        
        // Validar dirección
        Sort.Direction sortDirection = "desc".equals(direction) 
            ? Sort.Direction.DESC 
            : Sort.Direction.ASC;
        
        return Sort.by(sortDirection, field);
    }
}