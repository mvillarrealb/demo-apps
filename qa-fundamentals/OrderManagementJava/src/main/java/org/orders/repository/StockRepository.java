package org.orders.repository;

import org.orders.model.Stock;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StockRepository extends JpaRepository<Stock, Integer>, JpaSpecificationExecutor<Stock> {
    // Métodos CRUD y paginación incluidos por JpaRepository
    @EntityGraph(attributePaths = {"product", "product.category"})
    Page<Stock> findAll(@Nullable Specification<Stock> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"product", "product.category"})
    Optional<Stock> findById(Integer stockId);
}
