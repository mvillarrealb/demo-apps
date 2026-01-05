package org.orders.repository;

import org.orders.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Integer> {
    // Métodos CRUD ya incluidos por JpaRepository
}
