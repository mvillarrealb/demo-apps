package org.gh.copilot.backend_proyect.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.gh.copilot.backend_proyect.model.Transaction;
import org.gh.copilot.backend_proyect.model.TransactionType;
import org.gh.copilot.backend_proyect.dto.GroupedAmountDto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Repositorio para gestionar operaciones de persistencia de Transaction.
 */
@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    /**
     * Busca transacciones con filtros múltiples y paginación.
     */
    @Query("SELECT t FROM Transaction t LEFT JOIN t.category c WHERE " +
           "(:categoryId IS NULL OR t.categoryId = :categoryId) AND " +
           "(:type IS NULL OR t.type = :type) AND " +
           "(:fromDate IS NULL OR t.postedAt >= :fromDate) AND " +
           "(:toDate IS NULL OR t.postedAt <= :toDate) AND " +
           "(:minAmount IS NULL OR t.amount >= :minAmount) AND " +
           "(:maxAmount IS NULL OR t.amount <= :maxAmount) AND " +
           "(:q IS NULL OR LOWER(t.description) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           " LOWER(c.name) LIKE LOWER(CONCAT('%', :q, '%')))")
    Page<Transaction> findAllWithFilters(
        @Param("categoryId") Long categoryId,
        @Param("type") TransactionType type,
        @Param("fromDate") Instant fromDate,
        @Param("toDate") Instant toDate,
        @Param("minAmount") BigDecimal minAmount,
        @Param("maxAmount") BigDecimal maxAmount,
        @Param("q") String q,
        Pageable pageable
    );
    
    /**
     * Agrupa transacciones por categoría y calcula totales netos en un rango de fechas.
     * Opcionalmente filtra por accountId.
     * CREDIT suma positivo, DEBIT suma negativo.
     */
    @Query("SELECT new org.gh.copilot.backend_proyect.dto.GroupedAmountDto(" +
           "COALESCE(c.name, 'Sin categoría'), " +
           "SUM(CASE WHEN t.type = 'CREDIT' THEN t.amount ELSE -t.amount END), " +
           "COUNT(t), " +
           "t.currency) " +
           "FROM Transaction t LEFT JOIN t.category c " +
           "WHERE (:accountId IS NULL OR t.accountId = :accountId) AND " +
           "(:fromDate IS NULL OR t.postedAt >= :fromDate) AND " +
           "(:toDate IS NULL OR t.postedAt <= :toDate) " +
           "GROUP BY COALESCE(c.name, 'Sin categoría'), t.currency " +
           "ORDER BY COALESCE(c.name, 'Sin categoría')")
    List<GroupedAmountDto> findGroupedByCategory(
        @Param("accountId") String accountId,
        @Param("fromDate") Instant fromDate,
        @Param("toDate") Instant toDate
    );
}