import React from 'react';
import { useForm } from 'react-hook-form';
import { clsx } from 'clsx';
import { MagnifyingGlassIcon, FunnelIcon, XMarkIcon } from '@heroicons/react/24/outline';
import type { TransactionFiltersInput } from '../lib/validations';
import type { CategoryDto } from '../services/transactionApi';

interface FormData {
  categoryId: string;
  type: string;
  fromDate: string;
  toDate: string;
  minAmount: string;
  maxAmount: string;
  q: string;
  page: string;
  size: string;
  sort: string;
}

interface TransactionFiltersProps {
  onFiltersChange: (filters: TransactionFiltersInput) => void;
  categories: CategoryDto[];
  isLoading?: boolean;
  className?: string;
}

const TransactionFilters: React.FC<TransactionFiltersProps> = ({
  onFiltersChange,
  categories,
  isLoading = false,
  className,
}) => {
  const form = useForm<FormData>({
    defaultValues: {
      page: '0',
      size: '20',
      sort: 'postedAt,DESC',
      categoryId: '',
      type: '',
      fromDate: '',
      toDate: '',
      minAmount: '',
      maxAmount: '',
      q: '',
    },
  });

  const { register, handleSubmit, reset, formState: { errors } } = form;

  // Manejar envío del formulario
  const onSubmit = (data: FormData) => {
    // Convertir y limpiar datos
    const filters: Partial<TransactionFiltersInput> = {};
    
    if (data.categoryId) filters.categoryId = Number(data.categoryId);
    if (data.type && data.type !== '') filters.type = data.type as 'CREDIT' | 'DEBIT';
    if (data.fromDate) filters.fromDate = data.fromDate;
    if (data.toDate) filters.toDate = data.toDate;
    if (data.minAmount) filters.minAmount = Number(data.minAmount);
    if (data.maxAmount) filters.maxAmount = Number(data.maxAmount);
    if (data.q) filters.q = data.q;
    if (data.sort) filters.sort = data.sort;
    
    filters.page = Number(data.page) || 0;
    filters.size = Number(data.size) || 20;

    onFiltersChange(filters as TransactionFiltersInput);
  };

  // Limpiar todos los filtros
  const handleClearFilters = () => {
    reset({
      page: '0',
      size: '20',
      sort: 'postedAt,DESC',
      categoryId: '',
      type: '',
      fromDate: '',
      toDate: '',
      minAmount: '',
      maxAmount: '',
      q: '',
    });
    onFiltersChange({
      page: 0,
      size: 20,
      sort: 'postedAt,DESC',
    });
  };

  return (
    <div className={clsx('transaction-filters', className)}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {/* Barra de búsqueda */}
        <div className="flex gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-5 w-5 transform -translate-y-1/2 text-neutral-400" />
              <input
                {...register('q')}
                type="text"
                placeholder="Buscar por descripción..."
                className={clsx(
                  'input pl-10',
                  errors.q && 'border-error-500 focus:ring-error-500'
                )}
                disabled={isLoading}
              />
            </div>
          </div>
          
          <button
            type="submit"
            disabled={isLoading}
            className="btn btn-primary shrink-0"
          >
            <FunnelIcon className="h-5 w-5" />
            Filtrar
          </button>
          
          <button
            type="button"
            onClick={handleClearFilters}
            disabled={isLoading}
            className="btn btn-secondary shrink-0"
          >
            <XMarkIcon className="h-5 w-5" />
            Limpiar
          </button>
        </div>

        {/* Filtros avanzados */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Categoría */}
          <div>
            <label htmlFor="categoryId" className="block text-sm font-medium text-neutral-700 mb-1">
              Categoría
            </label>
            <select
              {...register('categoryId')}
              id="categoryId"
              className={clsx(
                'input',
                errors.categoryId && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            >
              <option value="">Todas las categorías</option>
              {categories.map((category) => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </select>
          </div>

          {/* Tipo de transacción */}
          <div>
            <label htmlFor="type" className="block text-sm font-medium text-neutral-700 mb-1">
              Tipo
            </label>
            <select
              {...register('type')}
              id="type"
              className={clsx(
                'input',
                errors.type && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            >
              <option value="">Todos los tipos</option>
              <option value="CREDIT">Ingreso</option>
              <option value="DEBIT">Gasto</option>
            </select>
          </div>

          {/* Fecha desde */}
          <div>
            <label htmlFor="fromDate" className="block text-sm font-medium text-neutral-700 mb-1">
              Desde
            </label>
            <input
              {...register('fromDate')}
              type="date"
              id="fromDate"
              className={clsx(
                'input',
                errors.fromDate && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            />
          </div>

          {/* Fecha hasta */}
          <div>
            <label htmlFor="toDate" className="block text-sm font-medium text-neutral-700 mb-1">
              Hasta
            </label>
            <input
              {...register('toDate')}
              type="date"
              id="toDate"
              className={clsx(
                'input',
                errors.toDate && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            />
          </div>
        </div>

        {/* Rango de montos */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label htmlFor="minAmount" className="block text-sm font-medium text-neutral-700 mb-1">
              Monto mínimo
            </label>
            <input
              {...register('minAmount')}
              type="number"
              step="0.01"
              min="0"
              id="minAmount"
              placeholder="0.00"
              className={clsx(
                'input',
                errors.minAmount && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            />
          </div>

          <div>
            <label htmlFor="maxAmount" className="block text-sm font-medium text-neutral-700 mb-1">
              Monto máximo
            </label>
            <input
              {...register('maxAmount')}
              type="number"
              step="0.01"
              min="0"
              id="maxAmount"
              placeholder="0.00"
              className={clsx(
                'input',
                errors.maxAmount && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            />
          </div>

          <div>
            <label htmlFor="sort" className="block text-sm font-medium text-neutral-700 mb-1">
              Ordenar por
            </label>
            <select
              {...register('sort')}
              id="sort"
              className={clsx(
                'input',
                errors.sort && 'border-error-500 focus:ring-error-500'
              )}
              disabled={isLoading}
            >
              <option value="postedAt,DESC">Fecha (más reciente)</option>
              <option value="postedAt,ASC">Fecha (más antiguo)</option>
              <option value="amount,DESC">Monto (mayor a menor)</option>
              <option value="amount,ASC">Monto (menor a mayor)</option>
              <option value="description,ASC">Descripción (A-Z)</option>
              <option value="description,DESC">Descripción (Z-A)</option>
            </select>
          </div>
        </div>

        {/* Paginación oculta */}
        <input {...register('page')} type="hidden" />
        <input {...register('size')} type="hidden" />
      </form>
    </div>
  );
};

export default TransactionFilters;