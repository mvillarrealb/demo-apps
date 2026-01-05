package org.orders.repository;

import org.orders.model.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Integer> {
    // Métodos CRUD y paginación incluidos por JpaRepository
    @EntityGraph(attributePaths = {"category"})
    Page<Product> findAll(Pageable pageable);
}
