package org.gh.copilot.backend_proyect.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.gh.copilot.backend_proyect.dto.CategoryDto;
import org.gh.copilot.backend_proyect.dto.CreateCategoryDto;
import org.gh.copilot.backend_proyect.model.Category;

/**
 * Mapper para conversión entre entidades Category y DTOs.
 */
@Mapper(componentModel = "spring")
public interface CategoryMapper {
    
    /**
     * Convierte una entidad Category a CategoryDto.
     */
    CategoryDto toDto(Category category);
    
    /**
     * Convierte CreateCategoryDto a entidad Category.
     * El id y createdAt se asignan automáticamente en la persistencia.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    Category toEntity(CreateCategoryDto createCategoryDto);
}