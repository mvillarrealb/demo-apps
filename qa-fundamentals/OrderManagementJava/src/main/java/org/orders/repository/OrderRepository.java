package org.orders.repository;


import org.orders.model.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Integer> {

    @EntityGraph(attributePaths = {"customer", "details", "details.product", "details.product.category"})
    Page<Order> findAll(Pageable pageable);

    @EntityGraph(attributePaths = {"customer", "details", "details.product", "details.product.category"})
    Optional<Order> findById(Integer orderNumber);
}
