package org.orders.controller;

import jakarta.persistence.criteria.Predicate;
import org.orders.model.Customer;
import org.orders.repository.CustomerRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/customers")
public class CustomersController {

    @Autowired
    private CustomerRepository customerRepository;

    // GET: api/customers?limit=10&offset=0&city=&state=
    @GetMapping
    public ResponseEntity<List<Customer>> getCustomers(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String state) {
        if (limit < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Limit must be greater than 0");
        }
        if (offset < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Offset must be greater than or equal to 0");
        }
        Pageable pageable = PageRequest.of(offset / limit, limit, Sort.by("firstName"));
        Page<Customer> page;
        if ((city != null && !city.isBlank()) || (state != null && !state.isBlank())) {
            page = customerRepository.findAll((root, query, cb) -> {
                Predicate predicate = cb.conjunction();
                if (city != null && !city.isBlank()) {
                    predicate = cb.and(predicate, cb.like(cb.lower(root.get("city")), "%" + city.toLowerCase() + "%"));
                }
                if (state != null && !state.isBlank()) {
                    predicate = cb.and(predicate, cb.like(cb.lower(root.get("state")), "%" + state.toLowerCase() + "%"));
                }
                return predicate;
            }, pageable);
        } else {
            page = customerRepository.findAll(pageable);
        }
        return ResponseEntity.ok(page.getContent());
    }

    // GET: api/customers/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Customer> getCustomer(@PathVariable Integer id) {
        Optional<Customer> customer = customerRepository.findById(id);
        return customer.map(ResponseEntity::ok)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
    }

    // POST: api/customers
    @PostMapping
    public ResponseEntity<Customer> createCustomer(@Valid @RequestBody Customer customer) {
        Customer created = customerRepository.save(customer);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT: api/customers/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Customer> updateCustomer(
            @PathVariable Integer id,
            @Valid @RequestBody Customer customer) {
        if (!id.equals(customer.getCustomerId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "ID mismatch between path and body");
        }
        if (!customerRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found");
        }
        Customer updated = customerRepository.save(customer);
        return ResponseEntity.ok(updated);
    }

    // DELETE: api/customers/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCustomer(@PathVariable Integer id) {
        if (!customerRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found");
        }
        customerRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
