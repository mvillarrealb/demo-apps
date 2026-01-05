import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { PlusIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline';
import { clsx } from 'clsx';
import TransactionFilters from '../components/TransactionFilters';
import NewTransactionModal from '../components/NewTransactionModal';
import { TransactionApiService } from '../services/transactionApi';
import type { 
  TransactionDto, 
  CategoryDto,
  PageTransactionDto
} from '../services/transactionApi';
import type { TransactionFiltersInput } from '../lib/validations';

// Estado de la página
interface TransactionsPageState {
  transactions: TransactionDto[];
  categories: CategoryDto[];
  pagination: {
    page: number;
    size: number;
    totalElements: number;
    totalPages: number;
  };
  isLoading: boolean;
  error: string | null;
  selectedTransaction: TransactionDto | null;
  isNewTransactionModalOpen: boolean;
  isEditMode: boolean;
}

const Transactions: React.FC = () => {
  const [state, setState] = useState<TransactionsPageState>({
    transactions: [],
    categories: [],
    pagination: {
      page: 0,
      size: 20,
      totalElements: 0,
      totalPages: 0,
    },
    isLoading: false,
    error: null,
    selectedTransaction: null,
    isNewTransactionModalOpen: false,
    isEditMode: false,
  });

  // Filtros actuales
  const [currentFilters, setCurrentFilters] = useState<TransactionFiltersInput>({
    page: 0,
    size: 20,
    sort: 'postedAt,DESC',
  });

  // Instancia de API (memo para evitar recrear en cada render)
  const transactionApi = useMemo(() => new TransactionApiService(), []);

  // Cargar categorías al montar el componente
  const loadCategories = useCallback(async () => {
    try {
      const categoriesResponse = await transactionApi.getCategories();
      // getCategories devuelve PageCategoryDto, necesitamos extraer el contenido
      const categories = categoriesResponse.content || [];
      setState(prev => ({ ...prev, categories }));
    } catch (error) {
      console.error('Error loading categories:', error);
      setState(prev => ({ 
        ...prev, 
        error: 'Error al cargar las categorías'
      }));
    }
  }, [transactionApi]);

  // Cargar transacciones
  const loadTransactions = useCallback(async (filters: TransactionFiltersInput) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));
    
    try {
      const response: PageTransactionDto = await transactionApi.getTransactions(filters);
      
      setState(prev => ({
        ...prev,
        transactions: response.content || [],
        pagination: {
          page: filters.page || 0,
          size: filters.size || 20,
          totalElements: response.totalElements || 0,
          totalPages: response.totalPages || 0,
        },
        isLoading: false,
      }));
    } catch (error) {
      console.error('Error loading transactions:', error);
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: 'Error al cargar las transacciones',
        transactions: [],
      }));
    }
  }, [transactionApi]);

  // Efecto para cargar datos iniciales
  useEffect(() => {
    loadCategories();
    loadTransactions(currentFilters);
  }, [loadCategories, loadTransactions, currentFilters]);

  // Manejar cambios de filtros
  const handleFiltersChange = useCallback((filters: TransactionFiltersInput) => {
    setCurrentFilters(filters);
    loadTransactions(filters);
  }, [loadTransactions]);

  // Manejar paginación
  const handlePageChange = useCallback((newPage: number) => {
    const newFilters = { ...currentFilters, page: newPage };
    setCurrentFilters(newFilters);
    loadTransactions(newFilters);
  }, [currentFilters, loadTransactions]);

  // Abrir modal para nueva transacción
  const handleNewTransaction = () => {
    setState(prev => ({
      ...prev,
      isNewTransactionModalOpen: true,
      isEditMode: false,
      selectedTransaction: null,
    }));
  };

  // Abrir modal para editar transacción
  const handleEditTransaction = (transaction: TransactionDto) => {
    setState(prev => ({
      ...prev,
      isNewTransactionModalOpen: true,
      isEditMode: true,
      selectedTransaction: transaction,
    }));
  };

  // Cerrar modal
  const handleCloseModal = () => {
    setState(prev => ({
      ...prev,
      isNewTransactionModalOpen: false,
      isEditMode: false,
      selectedTransaction: null,
    }));
  };

  // Manejar éxito en el modal (nueva transacción creada o editada)
  const handleTransactionSuccess = () => {
    handleCloseModal();
    // Recargar las transacciones
    loadTransactions(currentFilters);
  };

  // Eliminar transacción
  const handleDeleteTransaction = async (transactionId: number) => {
    if (!confirm('¿Está seguro de que desea eliminar esta transacción?')) {
      return;
    }

    try {
      // TODO: Implementar deleteTransaction en el API service
      // await transactionApi.deleteTransaction(transactionId);
      console.log('Delete transaction:', transactionId);
      // Recargar las transacciones
      loadTransactions(currentFilters);
    } catch (error) {
      console.error('Error deleting transaction:', error);
      setState(prev => ({ 
        ...prev, 
        error: 'Error al eliminar la transacción'
      }));
    }
  };

  // Formatear monto
  const formatAmount = (amount: number, type: 'CREDIT' | 'DEBIT') => {
    const formattedAmount = new Intl.NumberFormat('es-PE', {
      style: 'currency',
      currency: 'PEN',
    }).format(amount);

    return (
      <span className={clsx(
        'font-semibold',
        type === 'CREDIT' ? 'transaction-amount-credit' : 'transaction-amount-debit'
      )}>
        {type === 'CREDIT' ? '+' : '-'}{formattedAmount}
      </span>
    );
  };

  // Formatear fecha
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('es-PE', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  // Obtener nombre de categoría
  const getCategoryName = (categoryId?: number) => {
    if (!categoryId) return 'Sin categoría';
    const category = state.categories.find(c => c.id === categoryId);
    return category?.name || 'Sin categoría';
  };

  return (
    <div className="transactions-page">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-neutral-900">Transacciones</h1>
            <p className="text-neutral-600 mt-1">
              Gestiona tus ingresos y gastos
            </p>
          </div>
          <button
            onClick={handleNewTransaction}
            className="btn btn-primary"
            disabled={state.isLoading}
          >
            <PlusIcon className="h-5 w-5" />
            Nueva Transacción
          </button>
        </div>
      </div>

      {/* Filtros */}
      <div className="mb-6">
        <TransactionFilters
          onFiltersChange={handleFiltersChange}
          categories={state.categories}
          isLoading={state.isLoading}
        />
      </div>

      {/* Estado de error */}
      {state.error && (
        <div className="bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-md mb-6">
          <p>{state.error}</p>
        </div>
      )}

      {/* Lista de transacciones */}
      <div className="card">
        {/* Header de la tabla */}
        <div className="border-b border-neutral-200 px-6 py-4">
          <h2 className="text-lg font-semibold text-neutral-900">
            Transacciones 
            {state.pagination.totalElements > 0 && (
              <span className="text-sm font-normal text-neutral-500 ml-2">
                ({state.pagination.totalElements} resultados)
              </span>
            )}
          </h2>
        </div>

        {/* Contenido de la tabla */}
        <div className="min-h-96">
          {state.isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
              <span className="ml-3 text-neutral-600">Cargando transacciones...</span>
            </div>
          ) : state.transactions.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-neutral-400 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-neutral-900 mb-2">No hay transacciones</h3>
              <p className="text-neutral-600 mb-4">
                No se encontraron transacciones con los filtros aplicados.
              </p>
              <button
                onClick={handleNewTransaction}
                className="btn btn-primary"
              >
                <PlusIcon className="h-5 w-5" />
                Crear primera transacción
              </button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-neutral-200">
                <thead className="bg-neutral-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                      Fecha
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                      Descripción
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                      Categoría
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                      Monto
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-neutral-500 uppercase tracking-wider">
                      Acciones
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-neutral-200">
                  {state.transactions.map((transaction) => (
                    <tr key={transaction.id} className="hover:bg-neutral-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-neutral-900">
                        {formatDate(transaction.postedAt)}
                      </td>
                      <td className="px-6 py-4 text-sm text-neutral-900">
                        <div className="max-w-xs truncate" title={transaction.description}>
                          {transaction.description}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-neutral-600">
                        {getCategoryName(transaction.categoryId)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        {formatAmount(transaction.amount, transaction.type)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex items-center justify-end space-x-2">
                          <button
                            onClick={() => handleEditTransaction(transaction)}
                            className="text-primary-600 hover:text-primary-900 p-1 rounded-md hover:bg-primary-50"
                            title="Editar"
                          >
                            <PencilIcon className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteTransaction(transaction.id)}
                            className="text-error-600 hover:text-error-900 p-1 rounded-md hover:bg-error-50"
                            title="Eliminar"
                          >
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Paginación */}
        {state.pagination.totalPages > 1 && (
          <div className="border-t border-neutral-200 px-6 py-4">
            <div className="flex items-center justify-between">
              <div className="text-sm text-neutral-700">
                Mostrando{' '}
                <span className="font-medium">
                  {state.pagination.page * state.pagination.size + 1}
                </span>{' '}
                a{' '}
                <span className="font-medium">
                  {Math.min((state.pagination.page + 1) * state.pagination.size, state.pagination.totalElements)}
                </span>{' '}
                de{' '}
                <span className="font-medium">{state.pagination.totalElements}</span>{' '}
                resultados
              </div>

              <div className="flex items-center space-x-2">
                <button
                  onClick={() => handlePageChange(state.pagination.page - 1)}
                  disabled={state.pagination.page === 0 || state.isLoading}
                  className="btn btn-secondary btn-sm"
                >
                  Anterior
                </button>
                
                <span className="text-sm text-neutral-700">
                  Página {state.pagination.page + 1} de {state.pagination.totalPages}
                </span>
                
                <button
                  onClick={() => handlePageChange(state.pagination.page + 1)}
                  disabled={state.pagination.page >= state.pagination.totalPages - 1 || state.isLoading}
                  className="btn btn-secondary btn-sm"
                >
                  Siguiente
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Modal de nueva/editar transacción */}
      {state.isNewTransactionModalOpen && (
        <NewTransactionModal
          isOpen={state.isNewTransactionModalOpen}
          onClose={handleCloseModal}
          onSuccess={handleTransactionSuccess}
          categories={state.categories}
          transaction={state.selectedTransaction}
          isEditMode={state.isEditMode}
        />
      )}
    </div>
  );
};

export default Transactions;