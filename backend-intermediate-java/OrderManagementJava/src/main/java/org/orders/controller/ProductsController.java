package org.orders.controller;

import org.orders.model.Product;
import org.orders.repository.ProductRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/products")
public class ProductsController {

    @Autowired
    private ProductRepository productRepository;

    // GET: api/products?limit=10&offset=0
    @GetMapping
    public ResponseEntity<List<Product>> getProducts(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        if (limit < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Limit must be greater than 0");
        }
        if (offset < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Offset must be greater than or equal to 0");
        }
        Pageable pageable = PageRequest.of(offset / limit, limit, Sort.by("productName"));
        Page<Product> page = productRepository.findAll(pageable);
        return ResponseEntity.ok(page.getContent());
    }

    // GET: api/products/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Product> getProduct(@PathVariable Integer id) {
        Optional<Product> product = productRepository.findById(id);
        return product.map(ResponseEntity::ok)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
    }

    // POST: api/products
    @PostMapping
    public ResponseEntity<Product> createProduct(@Valid @RequestBody Product product) {
        Product created = productRepository.save(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT: api/products/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Product> updateProduct(
            @PathVariable Integer id,
            @Valid @RequestBody Product product) {
        if (!id.equals(product.getProductId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "ID mismatch between path and body");
        }
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
        }
        Product updated = productRepository.save(product);
        return ResponseEntity.ok(updated);
    }

    // DELETE: api/products/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Integer id) {
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
        }
        productRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
