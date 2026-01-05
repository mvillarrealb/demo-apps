package org.orders.controller;

import org.orders.model.Order;
import org.orders.model.OrderDetail;
import org.orders.model.Product;
import org.orders.repository.OrderRepository;
import org.orders.repository.CustomerRepository;
import org.orders.repository.ProductRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/orders")
public class OrdersController {

    @Autowired
    private OrderRepository orderRepository;
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Autowired
    private ProductRepository productRepository;

    // GET: api/orders?limit=10&offset=0
    @GetMapping
    public ResponseEntity<List<Order>> getOrders(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        if (limit < 1) {
            return ResponseEntity.badRequest().build();
        }
        if (offset < 0) {
            return ResponseEntity.badRequest().build();
        }
        Pageable pageable = PageRequest.of(offset / limit, limit, Sort.by("orderDate").descending());
        Page<Order> page = orderRepository.findAll(pageable);
        return ResponseEntity.ok(page.getContent());
    }

    // GET: api/orders/{orderNumber}
    @GetMapping("/{orderNumber}")
    public ResponseEntity<Order> getOrder(@PathVariable Integer orderNumber) {
        Optional<Order> order = orderRepository.findById(orderNumber);
        return order.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }

    // POST: api/orders
    @PostMapping
    public ResponseEntity<Order> createOrder(@Valid @RequestBody Order order) {
        // Validate customer exists
        boolean customerExists = customerRepository.existsById(order.getCustomerId());
        if (!customerExists) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, 
                "Customer with ID " + order.getCustomerId() + " not found");
        }

        // Validate products exist and calculate total
        double totalAmount = 0;
        for (OrderDetail detail : order.getDetails()) {
            Optional<Product> productOpt = productRepository.findById(detail.getProductId());
            if (productOpt.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, 
                    "Product with ID " + detail.getProductId() + " not found");
            }
            
            Product product = productOpt.get();
            detail.setOrder(order);
            detail.setAmount(product.getPrice() * detail.getQuantity());
            totalAmount += detail.getAmount();
        }

        // Set the calculated total and order date
        order.setTotal(totalAmount);
        order.setOrderDate(LocalDate.now());

        Order created = orderRepository.save(order);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT: api/orders/{orderNumber}
    @PutMapping("/{orderNumber}")
    public ResponseEntity<Order> updateOrder(
            @PathVariable Integer orderNumber,
            @Valid @RequestBody Order order) {
        if (!orderNumber.equals(order.getOrderNumber())) {
            return ResponseEntity.badRequest().build();
        }
        if (!orderRepository.existsById(orderNumber)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        Order updated = orderRepository.save(order);
        return ResponseEntity.ok(updated);
    }

    // DELETE: api/orders/{orderNumber}
    @DeleteMapping("/{orderNumber}")
    public ResponseEntity<Void> deleteOrder(@PathVariable Integer orderNumber) {
        if (!orderRepository.existsById(orderNumber)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        orderRepository.deleteById(orderNumber);
        return ResponseEntity.noContent().build();
    }
}
