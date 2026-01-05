package org.gh.copilot.backend_proyect.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.gh.copilot.backend_proyect.model.Category;

/**
 * Repositorio para gestionar operaciones de persistencia de Category.
 */
@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
    
    /**
     * Busca categorías por nombre (búsqueda parcial, case-insensitive).
     */
    @Query("SELECT c FROM Category c WHERE " +
           "(:q IS NULL OR LOWER(c.name) LIKE LOWER(CONCAT('%', :q, '%')))")
    Page<Category> findAllWithFilters(@Param("q") String q, Pageable pageable);
    
    /**
     * Verifica si existe una categoría con el nombre dado (case-insensitive).
     */
    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM Category c " +
           "WHERE LOWER(c.name) = LOWER(:name)")
    boolean existsByNameIgnoreCase(@Param("name") String name);
}