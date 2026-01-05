import axios from 'axios';
import type { AxiosInstance, AxiosResponse } from 'axios';

// Base URL configurable - puede venir de variables de entorno
const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';

// Tipos basados en el OpenAPI
export interface CategoryDto {
  id: number;
  name: string;
  colorHex?: string;
  createdAt: string;
}

export interface CreateCategoryDto {
  name: string;
  colorHex?: string;
}

export interface TransactionDto {
  id: number;
  accountId: string;
  postedAt: string;
  amount: number;
  type: 'CREDIT' | 'DEBIT';
  currency: string;
  description: string;
  categoryId?: number;
  category?: CategoryDto;
  createdAt: string;
}

export interface CreateTransactionDto {
  accountId: string;
  postedAt: string;
  amount: number;
  type: 'CREDIT' | 'DEBIT';
  currency: string;
  description: string;
  categoryId?: number;
}

export interface GroupedAmountDto {
  key: string;
  totalAmount: number;
  count: number;
  currency: string;
}

export interface PageCategoryDto {
  content: CategoryDto[];
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
  numberOfElements: number;
}

export interface PageTransactionDto {
  content: TransactionDto[];
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
  numberOfElements: number;
}

// Parámetros de consulta para transacciones
export interface GetTransactionsParams {
  page?: number;
  size?: number;
  sort?: string;
  categoryId?: number;
  type?: 'CREDIT' | 'DEBIT';
  fromDate?: string;
  toDate?: string;
  minAmount?: number;
  maxAmount?: number;
  q?: string;
}

// Parámetros para categorías
export interface GetCategoriesParams {
  page?: number;
  size?: number;
  sort?: string;
  q?: string;
}

// Parámetros para agregaciones
export interface GetTransactionsGroupedByParams {
  series: string;
  accountId?: string;
  fromDate?: string;
  toDate?: string;
}

// Estado de loading y errores
export interface ApiState {
  loading: boolean;
  error: string | null;
}

class TransactionApiService {
  private api: AxiosInstance;
  private loadingState: Set<string> = new Set();
  private errorCallbacks: ((error: string) => void)[] = [];

  constructor() {
    this.api = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Interceptores para manejo de errores globales
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        const errorMessage = this.handleError(error);
        this.notifyError(errorMessage);
        return Promise.reject(error);
      }
    );
  }

  // Registro de callbacks para errores
  onError(callback: (error: string) => void) {
    this.errorCallbacks.push(callback);
  }

  private notifyError(error: string) {
    this.errorCallbacks.forEach(callback => callback(error));
  }

  private handleError(error: unknown): string {
    if (axios.isAxiosError(error) && error.response) {
      // Error del servidor con respuesta
      const status = error.response.status;
      const message = error.response.data?.message || error.response.statusText;
      
      switch (status) {
        case 400:
          return `Error de validación: ${message}`;
        case 404:
          return 'Recurso no encontrado';
        case 500:
          return 'Error interno del servidor';
        default:
          return `Error ${status}: ${message}`;
      }
    } else if (axios.isAxiosError(error) && error.request) {
      // Error de red
      return 'Error de conexión con el servidor';
    } else if (error instanceof Error) {
      // Error en la configuración
      return `Error: ${error.message}`;
    } else {
      // Error desconocido
      return 'Error desconocido';
    }
  }

  private setLoading(key: string, loading: boolean) {
    if (loading) {
      this.loadingState.add(key);
    } else {
      this.loadingState.delete(key);
    }
  }

  isLoading(key?: string): boolean {
    if (key) {
      return this.loadingState.has(key);
    }
    return this.loadingState.size > 0;
  }

  // Métodos para categorías
  async getCategories(params: GetCategoriesParams = {}): Promise<PageCategoryDto> {
    const loadingKey = 'getCategories';
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<PageCategoryDto> = await this.api.get('/api/categories', {
        params
      });
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  async getCategoryById(id: number): Promise<CategoryDto> {
    const loadingKey = `getCategory-${id}`;
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<CategoryDto> = await this.api.get(`/api/categories/${id}`);
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  async createCategory(category: CreateCategoryDto): Promise<CategoryDto> {
    const loadingKey = 'createCategory';
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<CategoryDto> = await this.api.post('/api/categories', category);
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  // Métodos para transacciones
  async getTransactions(params: GetTransactionsParams = {}): Promise<PageTransactionDto> {
    const loadingKey = 'getTransactions';
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<PageTransactionDto> = await this.api.get('/api/transactions', {
        params
      });
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  async getTransactionById(id: number): Promise<TransactionDto> {
    const loadingKey = `getTransaction-${id}`;
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<TransactionDto> = await this.api.get(`/api/transactions/${id}`);
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  async createTransaction(data: CreateTransactionDto): Promise<TransactionDto> {
    const loadingKey = 'createTransaction';
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<TransactionDto> = await this.api.post('/api/transactions', data);
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  // Métodos para agregaciones usando el endpoint real del OpenAPI
  async getTransactionsGroupedBy(params: GetTransactionsGroupedByParams): Promise<GroupedAmountDto[]> {
    const loadingKey = 'getTransactionsGroupedBy';
    this.setLoading(loadingKey, true);
    
    try {
      const response: AxiosResponse<GroupedAmountDto[]> = await this.api.get('/api/transactions/groupedBy', {
        params
      });
      return response.data;
    } finally {
      this.setLoading(loadingKey, false);
    }
  }

  // Método conveniente para obtener gastos por categoría usando el endpoint real
  async getExpensesByCategory(accountId?: string, fromDate?: string, toDate?: string): Promise<GroupedAmountDto[]> {
    return this.getTransactionsGroupedBy({
      series: 'category',
      accountId,
      fromDate,
      toDate
    });
  }
}

// Instancia singleton del servicio
export const transactionApi = new TransactionApiService();

// Exportar también la clase para casos avanzados
export { TransactionApiService };