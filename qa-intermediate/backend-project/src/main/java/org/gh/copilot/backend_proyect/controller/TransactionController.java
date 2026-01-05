package org.gh.copilot.backend_proyect.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.gh.copilot.backend_proyect.dto.CreateTransactionDto;
import org.gh.copilot.backend_proyect.dto.GroupedAmountDto;
import org.gh.copilot.backend_proyect.dto.TransactionDto;
import org.gh.copilot.backend_proyect.model.TransactionType;
import org.gh.copilot.backend_proyect.service.TransactionService;

import java.math.BigDecimal;
import java.util.List;

/**
 * Controlador REST para gestionar transacciones financieras.
 */
@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {
    
    private final TransactionService transactionService;
    
    /**
     * Crea una nueva transacción.
     * POST /api/transactions
     */
    @PostMapping
    public ResponseEntity<TransactionDto> create(@Valid @RequestBody CreateTransactionDto createTransactionDto) {
        TransactionDto createdTransaction = transactionService.create(createTransactionDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdTransaction);
    }
    
    /**
     * Obtiene una transacción por ID.
     * GET /api/transactions/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<TransactionDto> getById(@PathVariable Long id) {
        TransactionDto transaction = transactionService.findById(id);
        return ResponseEntity.ok(transaction);
    }
    
    /**
     * Obtiene todas las transacciones con filtros opcionales y paginación.
     * GET /api/transactions?categoryId=&type=&fromDate=&toDate=&minAmount=&maxAmount=&q=&page=&size=&sort=
     */
    @GetMapping
    public ResponseEntity<Page<TransactionDto>> getAll(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) TransactionType type,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate,
            @RequestParam(required = false) BigDecimal minAmount,
            @RequestParam(required = false) BigDecimal maxAmount,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "postedAt,DESC") String sort) {
        
        Page<TransactionDto> transactions = transactionService.findAll(
            categoryId, type, fromDate, toDate, minAmount, maxAmount, q, page, size, sort
        );
        return ResponseEntity.ok(transactions);
    }
    
    /**
     * Obtiene agregaciones agrupadas por categoría en un rango de fechas, opcionalmente filtradas por cuenta.
     * GET /api/transactions/groupedBy?series=category&accountId=&fromDate=&toDate=
     */
    @GetMapping("/groupedBy")
    public ResponseEntity<List<GroupedAmountDto>> getGroupedBy(
            @RequestParam String series,
            @RequestParam(required = false) String accountId,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        
        List<GroupedAmountDto> groupedAmounts = transactionService.findGroupedBy(series, accountId, fromDate, toDate);
        return ResponseEntity.ok(groupedAmounts);
    }
}