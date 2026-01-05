import React, { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { clsx } from 'clsx';
import { XMarkIcon, CalendarIcon, CurrencyDollarIcon } from '@heroicons/react/24/outline';
import { TransactionApiService } from '../services/transactionApi';
import type { CategoryDto, TransactionDto, CreateTransactionDto } from '../services/transactionApi';

interface FormData {
  accountId: string;
  amount: string;
  type: 'CREDIT' | 'DEBIT';
  currency: string;
  description: string;
  categoryId: string;
  postedAt: string;
}

interface NewTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  categories: CategoryDto[];
  transaction?: TransactionDto | null;
  isEditMode?: boolean;
}

const NewTransactionModal: React.FC<NewTransactionModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  categories,
  transaction,
  isEditMode = false,
}) => {
  const transactionApi = new TransactionApiService();

  // Configurar formulario con react-hook-form
  const form = useForm<FormData>({
    defaultValues: {
      accountId: 'main-account',
      amount: '0',
      type: 'DEBIT',
      currency: 'PEN',
      description: '',
      categoryId: '',
      postedAt: new Date().toISOString().split('T')[0],
    },
  });

  const { register, handleSubmit, reset, setValue, watch, formState: { errors, isSubmitting } } = form;
  
  // Observar tipo de transacción para cambiar estilos
  const watchedType = watch('type');

  // Efecto para cargar datos de transacción en modo edición
  useEffect(() => {
    if (isEditMode && transaction) {
      setValue('accountId', transaction.accountId || 'main-account');
      setValue('amount', transaction.amount.toString());
      setValue('type', transaction.type);
      setValue('currency', transaction.currency);
      setValue('description', transaction.description);
      setValue('categoryId', transaction.categoryId?.toString() || '');
      const date = new Date(transaction.postedAt);
      setValue('postedAt', date.toISOString().split('T')[0]);
    } else {
      reset({
        accountId: 'main-account',
        amount: '0',
        type: 'DEBIT',
        currency: 'PEN',
        description: '',
        categoryId: '',
        postedAt: new Date().toISOString().split('T')[0],
      });
    }
  }, [isEditMode, transaction, setValue, reset]);

  // Manejar envío del formulario
  const onSubmit = async (data: FormData) => {
    try {
      // Convertir datos del formulario al formato de la API
      const transactionData: CreateTransactionDto = {
        accountId: data.accountId,
        amount: parseFloat(data.amount),
        type: data.type,
        currency: data.currency,
        description: data.description,
        categoryId: data.categoryId ? parseInt(data.categoryId) : undefined,
        postedAt: data.postedAt,
      };

      if (isEditMode && transaction?.id) {
        // TODO: Implementar updateTransaction en el API service
        console.log('Update transaction:', { id: transaction.id, ...transactionData });
      } else {
        // Crear nueva transacción
        await transactionApi.createTransaction(transactionData);
      }
      
      // Cerrar modal y notificar éxito
      onSuccess();
    } catch (error) {
      console.error('Error saving transaction:', error);
      // TODO: Mostrar mensaje de error al usuario
    }
  };

  // Manejar cierre del modal
  const handleClose = () => {
    reset();
    onClose();
  };

  // No renderizar si no está abierto
  if (!isOpen) return null;

  return (
    <div className="modal-overlay">
      <div className="modal">
        {/* Header del modal */}
        <div className="modal-header">
          <h2 className="modal-title">
            {isEditMode ? 'Editar Transacción' : 'Nueva Transacción'}
          </h2>
          <button
            type="button"
            onClick={handleClose}
            className="modal-close-btn"
            disabled={isSubmitting}
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        {/* Contenido del modal */}
        <form onSubmit={handleSubmit(onSubmit)} className="modal-content">
          {/* Tipo de transacción */}
          <div className="form-group">
            <label className="form-label required">
              Tipo de transacción
            </label>
            <div className="flex gap-4">
              <label className={clsx(
                'radio-card',
                watchedType === 'CREDIT' && 'radio-card-selected'
              )}>
                <input
                  {...register('type')}
                  type="radio"
                  value="CREDIT"
                  className="sr-only"
                />
                <div className="flex items-center">
                  <div className="transaction-amount-credit text-lg font-semibold">+</div>
                  <div className="ml-2">
                    <div className="font-medium">Ingreso</div>
                    <div className="text-sm text-neutral-600">Dinero que entra</div>
                  </div>
                </div>
              </label>
              
              <label className={clsx(
                'radio-card',
                watchedType === 'DEBIT' && 'radio-card-selected'
              )}>
                <input
                  {...register('type')}
                  type="radio"
                  value="DEBIT"
                  className="sr-only"
                />
                <div className="flex items-center">
                  <div className="transaction-amount-debit text-lg font-semibold">-</div>
                  <div className="ml-2">
                    <div className="font-medium">Gasto</div>
                    <div className="text-sm text-neutral-600">Dinero que sale</div>
                  </div>
                </div>
              </label>
            </div>
          </div>

          {/* Descripción */}
          <div className="form-group">
            <label htmlFor="description" className="form-label required">
              Descripción
            </label>
            <input
              {...register('description', { required: 'La descripción es obligatoria' })}
              type="text"
              id="description"
              placeholder="Ej: Compra en supermercado, Salario, etc."
              className={clsx('input', errors.description && 'input-error')}
              disabled={isSubmitting}
            />
            {errors.description && (
              <p className="form-error">{errors.description.message}</p>
            )}
          </div>

          {/* Monto y Moneda */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="md:col-span-2">
              <label htmlFor="amount" className="form-label required">
                Monto
              </label>
              <div className="relative">
                <CurrencyDollarIcon className="absolute left-3 top-1/2 h-5 w-5 transform -translate-y-1/2 text-neutral-400" />
                <input
                  {...register('amount', { 
                    required: 'El monto es obligatorio',
                    pattern: {
                      value: /^\d+(\.\d{1,2})?$/,
                      message: 'Ingrese un monto válido'
                    }
                  })}
                  type="number"
                  step="0.01"
                  min="0"
                  id="amount"
                  placeholder="0.00"
                  className={clsx('input pl-10', errors.amount && 'input-error')}
                  disabled={isSubmitting}
                />
              </div>
              {errors.amount && (
                <p className="form-error">{errors.amount.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="currency" className="form-label required">
                Moneda
              </label>
              <select
                {...register('currency')}
                id="currency"
                className="input"
                disabled={isSubmitting}
              >
                <option value="PEN">PEN (Soles)</option>
                <option value="USD">USD (Dólares)</option>
                <option value="EUR">EUR (Euros)</option>
              </select>
            </div>
          </div>

          {/* Categoría */}
          <div className="form-group">
            <label htmlFor="categoryId" className="form-label">
              Categoría
            </label>
            <select
              {...register('categoryId')}
              id="categoryId"
              className="input"
              disabled={isSubmitting}
            >
              <option value="">Sin categoría</option>
              {categories.map((category) => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </select>
          </div>

          {/* Fecha */}
          <div className="form-group">
            <label htmlFor="postedAt" className="form-label required">
              Fecha de la transacción
            </label>
            <div className="relative">
              <CalendarIcon className="absolute left-3 top-1/2 h-5 w-5 transform -translate-y-1/2 text-neutral-400" />
              <input
                {...register('postedAt', { required: 'La fecha es obligatoria' })}
                type="date"
                id="postedAt"
                className={clsx('input pl-10', errors.postedAt && 'input-error')}
                disabled={isSubmitting}
              />
            </div>
            {errors.postedAt && (
              <p className="form-error">{errors.postedAt.message}</p>
            )}
          </div>

          {/* Cuenta (oculta por ahora) */}
          <input {...register('accountId')} type="hidden" value="main-account" />

          {/* Botones de acción */}
          <div className="modal-footer">
            <button
              type="button"
              onClick={handleClose}
              className="btn btn-secondary"
              disabled={isSubmitting}
            >
              Cancelar
            </button>
            <button
              type="submit"
              className={clsx(
                'btn',
                watchedType === 'CREDIT' ? 'btn-success' : 'btn-primary'
              )}
              disabled={isSubmitting}
            >
              {isSubmitting ? (
                <div className="flex items-center">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
                  Guardando...
                </div>
              ) : (
                isEditMode ? 'Actualizar' : 'Crear Transacción'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default NewTransactionModal;