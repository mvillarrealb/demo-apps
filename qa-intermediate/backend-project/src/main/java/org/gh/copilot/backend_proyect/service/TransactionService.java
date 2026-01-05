package org.gh.copilot.backend_proyect.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.gh.copilot.backend_proyect.dto.CreateTransactionDto;
import org.gh.copilot.backend_proyect.dto.GroupedAmountDto;
import org.gh.copilot.backend_proyect.dto.TransactionDto;
import org.gh.copilot.backend_proyect.mapper.TransactionMapper;
import org.gh.copilot.backend_proyect.model.Transaction;
import org.gh.copilot.backend_proyect.model.TransactionType;
import org.gh.copilot.backend_proyect.repository.CategoryRepository;
import org.gh.copilot.backend_proyect.repository.TransactionRepository;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Set;

/**
 * Servicio para gestionar operaciones de negocio relacionadas con transacciones.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionService {
    
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionMapper transactionMapper;
    
    // Zona horaria de referencia para agregaciones
    private static final ZoneId LIMA_ZONE = ZoneId.of("America/Lima");
    
    // Campos permitidos para ordenamiento
    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("postedAt", "amount", "description", "createdAt");
    
    // Series permitidas para agrupación
    private static final Set<String> ALLOWED_SERIES = Set.of("category");
    
    /**
     * Crea una nueva transacción.
     */
    @Transactional
    public TransactionDto create(CreateTransactionDto createTransactionDto) {
        // Validar categoría si se especifica
        if (createTransactionDto.getCategoryId() != null) {
            if (!categoryRepository.existsById(createTransactionDto.getCategoryId())) {
                throw new IllegalArgumentException("Categoría no encontrada con ID: " + createTransactionDto.getCategoryId());
            }
        }
        
        Transaction transaction = transactionMapper.toEntity(createTransactionDto);
        Transaction savedTransaction = transactionRepository.save(transaction);
        return transactionMapper.toDto(savedTransaction);
    }
    
    /**
     * Busca una transacción por ID.
     */
    public TransactionDto findById(Long id) {
        Transaction transaction = transactionRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Transacción no encontrada con ID: " + id));
        return transactionMapper.toDto(transaction);
    }
    
    /**
     * Busca transacciones con filtros y paginación.
     */
    public Page<TransactionDto> findAll(
            Long categoryId, 
            TransactionType type, 
            String fromDate, 
            String toDate,
            BigDecimal minAmount, 
            BigDecimal maxAmount, 
            String q, 
            int page, 
            int size, 
            String sort) {
        
        // Normalizar parámetros de paginación
        page = Math.max(0, page);
        size = Math.max(1, Math.min(100, size));
        
        // Convertir fechas
        Instant fromInstant = parseDate(fromDate, true);
        Instant toInstant = parseDate(toDate, false);
        
        // Validar rango de fechas
        if (fromInstant != null && toInstant != null && fromInstant.isAfter(toInstant)) {
            throw new IllegalArgumentException("La fecha desde no puede ser posterior a la fecha hasta");
        }
        
        // Validar montos
        if (minAmount != null && minAmount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("El monto mínimo no puede ser negativo");
        }
        if (maxAmount != null && maxAmount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("El monto máximo no puede ser negativo");
        }
        if (minAmount != null && maxAmount != null && minAmount.compareTo(maxAmount) > 0) {
            throw new IllegalArgumentException("El monto mínimo no puede ser mayor al monto máximo");
        }
        
        // Validar y crear ordenamiento
        Sort sortObj = createSort(sort);
        
        Pageable pageable = PageRequest.of(page, size, sortObj);
        Page<Transaction> transactions = transactionRepository.findAllWithFilters(
            categoryId, type, fromInstant, toInstant, minAmount, maxAmount, q, pageable
        );
        
        return transactions.map(transactionMapper::toDto);
    }
    
    /**
     * Obtiene agregaciones agrupadas por categoría, opcionalmente filtradas por accountId.
     */
    public List<GroupedAmountDto> findGroupedBy(String series, String accountId, String fromDate, String toDate) {
        // Validar serie permitida
        if (!ALLOWED_SERIES.contains(series)) {
            throw new IllegalArgumentException("Serie no permitida: " + series + ". Valores permitidos: " + ALLOWED_SERIES);
        }
        
        // Convertir fechas
        Instant fromInstant = parseDate(fromDate, true);
        Instant toInstant = parseDate(toDate, false);
        
        // Validar rango de fechas
        if (fromInstant != null && toInstant != null && fromInstant.isAfter(toInstant)) {
            throw new IllegalArgumentException("La fecha desde no puede ser posterior a la fecha hasta");
        }
        
        return transactionRepository.findGroupedByCategory(accountId, fromInstant, toInstant);
    }
    
    /**
     * Convierte fecha string (yyyy-MM-dd) a Instant usando zona horaria Lima.
     */
    private Instant parseDate(String dateStr, boolean isStartOfDay) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return null;
        }
        
        try {
            LocalDate localDate = LocalDate.parse(dateStr.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
            
            if (isStartOfDay) {
                return localDate.atStartOfDay(LIMA_ZONE).toInstant();
            } else {
                return localDate.atTime(23, 59, 59, 999_000_000).atZone(LIMA_ZONE).toInstant();
            }
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Formato de fecha inválido: " + dateStr + ". Use formato yyyy-MM-dd");
        }
    }
    
    /**
     * Crea objeto Sort validando los campos permitidos.
     */
    private Sort createSort(String sortParam) {
        if (sortParam == null || sortParam.trim().isEmpty()) {
            return Sort.by(Sort.Direction.DESC, "postedAt"); // Default
        }
        
        String[] parts = sortParam.split(",");
        if (parts.length != 2) {
            return Sort.by(Sort.Direction.DESC, "postedAt"); // Default
        }
        
        String field = parts[0].trim();
        String direction = parts[1].trim().toLowerCase();
        
        // Validar campo permitido
        if (!ALLOWED_SORT_FIELDS.contains(field)) {
            field = "postedAt"; // Default
        }
        
        // Validar dirección
        Sort.Direction sortDirection = "desc".equals(direction) 
            ? Sort.Direction.DESC 
            : Sort.Direction.ASC;
        
        return Sort.by(sortDirection, field);
    }
}