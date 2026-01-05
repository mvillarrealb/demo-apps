package org.orders.controller;

import org.orders.model.Category;
import org.orders.repository.CategoryRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/categories")
public class CategoriesController {
    
    @Autowired
    private CategoryRepository categoryRepository;

    // GET: api/categories?limit=10&offset=0
    @GetMapping
    public ResponseEntity<List<Category>> getCategories(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        if (limit < 1 || offset < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid pagination parameters");
        }
        Pageable pageable = PageRequest.of(offset / limit, limit, Sort.by("categoryName"));
        return ResponseEntity.ok(categoryRepository.findAll(pageable).getContent());
    }

    // GET: api/categories/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Category> getCategory(@PathVariable Integer id) {
        Optional<Category> category = categoryRepository.findById(id);
        return category.map(ResponseEntity::ok)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));
    }

    // POST: api/categories
    @PostMapping
    public ResponseEntity<Category> createCategory(@Valid @RequestBody Category category) {
        Category created = categoryRepository.save(category);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT: api/categories/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Category> updateCategory(
            @PathVariable Integer id,
            @Valid @RequestBody Category category) {
        if (!id.equals(category.getCategoryId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "ID mismatch between path and body");
        }
        if (!categoryRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found");
        }
        Category updated = categoryRepository.save(category);
        return ResponseEntity.ok(updated);
    }

    // DELETE: api/categories/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable Integer id) {
        if (!categoryRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found");
        }
        categoryRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
