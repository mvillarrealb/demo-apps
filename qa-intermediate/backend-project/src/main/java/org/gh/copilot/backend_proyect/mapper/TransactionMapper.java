package org.gh.copilot.backend_proyect.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.gh.copilot.backend_proyect.dto.TransactionDto;
import org.gh.copilot.backend_proyect.dto.CreateTransactionDto;
import org.gh.copilot.backend_proyect.model.Transaction;

/**
 * Mapper para conversión entre entidades Transaction y DTOs.
 */
@Mapper(componentModel = "spring", uses = {CategoryMapper.class})
public interface TransactionMapper {
    
    /**
     * Convierte una entidad Transaction a TransactionDto.
     */
    TransactionDto toDto(Transaction transaction);
    
    /**
     * Convierte CreateTransactionDto a entidad Transaction.
     * El id, createdAt y category se asignan en la persistencia.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "category", ignore = true)
    Transaction toEntity(CreateTransactionDto createTransactionDto);
}