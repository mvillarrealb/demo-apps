package org.orders.controller;

import org.orders.model.Stock;
import org.orders.repository.StockRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/products/{productId}/stock")
public class StockController {

    @Autowired
    private StockRepository stockRepository;

    // GET: api/products/{productId}/stock?limit=10&offset=0
    @GetMapping
    public ResponseEntity<List<Stock>> getProductStock(
            @PathVariable Integer productId,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        if (limit < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Limit must be greater than 0");
        }
        if (offset < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Offset must be greater than or equal to 0");
        }
        Pageable pageable = PageRequest.of(offset / limit, limit, Sort.by("stockId"));
        Page<Stock> page = stockRepository.findAll(
            (root, query, cb) -> cb.equal(root.get("productId"), productId), pageable);
        return ResponseEntity.ok(page.getContent());
    }

    // GET: api/products/{productId}/stock/{stockId}
    @GetMapping("/{stockId}")
    public ResponseEntity<Stock> getProductStockById(@PathVariable Integer productId, @PathVariable Integer stockId) {
        Optional<Stock> stock = stockRepository.findById(stockId);
        if (stock.isPresent() && stock.get().getProductId().equals(productId)) {
            return ResponseEntity.ok(stock.get());
        }
        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Stock not found for this product");
    }

    // POST: api/products/{productId}/stock
    @PostMapping
    public ResponseEntity<Stock> createProductStock(@PathVariable Integer productId, @Valid @RequestBody Stock stock) {
        if (!productId.equals(stock.getProductId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Product ID mismatch between path and body");
        }
        Stock created = stockRepository.save(stock);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT: api/products/{productId}/stock/{stockId}
    @PutMapping("/{stockId}")
    public ResponseEntity<Stock> updateProductStock(
            @PathVariable Integer productId,
            @PathVariable Integer stockId,
            @Valid @RequestBody Stock stock) {
        if (!stockId.equals(stock.getStockId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Stock ID mismatch between path and body");
        }
        if (!productId.equals(stock.getProductId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Product ID mismatch between path and body");
        }
        if (!stockRepository.existsById(stockId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Stock not found");
        }
        Stock updated = stockRepository.save(stock);
        return ResponseEntity.ok(updated);
    }

    // DELETE: api/products/{productId}/stock/{stockId}
    @DeleteMapping("/{stockId}")
    public ResponseEntity<Void> deleteProductStock(@PathVariable Integer productId, @PathVariable Integer stockId) {
        Optional<Stock> stock = stockRepository.findById(stockId);
        if (stock.isEmpty() || !stock.get().getProductId().equals(productId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Stock not found for this product");
        }
        stockRepository.deleteById(stockId);
        return ResponseEntity.noContent().build();
    }
}
