import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { 
  CurrencyDollarIcon, 
  ArrowTrendingUpIcon, 
  ArrowTrendingDownIcon,
  CalendarIcon,
  ChartPieIcon
} from '@heroicons/react/24/outline';
import { 
  PieChart, 
  Pie, 
  Cell, 
  ResponsiveContainer, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend
} from 'recharts';
import { clsx } from 'clsx';
import { TransactionApiService } from '../services/transactionApi';
import type { 
  CategoryDto, 
  GroupedAmountDto, 
  TransactionDto 
} from '../services/transactionApi';

// Estado del dashboard
interface DashboardState {
  categories: CategoryDto[];
  recentTransactions: TransactionDto[];
  monthlyStats: {
    totalIncome: number;
    totalExpenses: number;
    netIncome: number;
    transactionCount: number;
  };
  expensesByCategory: Array<{
    name: string;
    value: number;
    color: string;
  }>;
  monthlyTrends: Array<{
    month: string;
    income: number;
    expenses: number;
  }>;
  isLoading: boolean;
  error: string | null;
}

// Colores para el gráfico de pie
const CHART_COLORS = [
  '#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd',
  '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf'
];

const Dashboard: React.FC = () => {
  const [state, setState] = useState<DashboardState>({
    categories: [],
    recentTransactions: [],
    monthlyStats: {
      totalIncome: 0,
      totalExpenses: 0,
      netIncome: 0,
      transactionCount: 0,
    },
    expensesByCategory: [],
    monthlyTrends: [],
    isLoading: true,
    error: null,
  });

  // Instancia del servicio API
  const transactionApi = useMemo(() => new TransactionApiService(), []);

  // Cargar datos del dashboard usando solo endpoints reales del OpenAPI
  const loadDashboardData = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      // Cargar datos en paralelo usando SOLO endpoints que existen en el OpenAPI
      const [
        categoriesResponse,
        transactionsResponse,
        expensesAggregation
      ] = await Promise.all([
        transactionApi.getCategories(),
        transactionApi.getTransactions({ page: 0, size: 100, sort: 'postedAt,DESC' }), // Más transacciones para estadísticas
        transactionApi.getExpensesByCategory() // Usa el endpoint real /api/transactions/groupedBy
      ]);

      // Procesar categorías
      const categories = categoriesResponse.content || [];

      // Procesar todas las transacciones (no solo las recientes)
      const allTransactions = transactionsResponse.content || [];
      const recentTransactions = allTransactions.slice(0, 5); // Solo las 5 más recientes para mostrar

      // Calcular estadísticas mensuales desde las transacciones reales
      const currentMonth = new Date();
      const monthlyTransactions = allTransactions.filter((t: TransactionDto) => {
        const transactionDate = new Date(t.postedAt);
        return transactionDate.getMonth() === currentMonth.getMonth() &&
               transactionDate.getFullYear() === currentMonth.getFullYear();
      });

      const totalIncome = monthlyTransactions
        .filter((t: TransactionDto) => t.type === 'CREDIT')
        .reduce((sum: number, t: TransactionDto) => sum + t.amount, 0);

      const totalExpenses = monthlyTransactions
        .filter((t: TransactionDto) => t.type === 'DEBIT')
        .reduce((sum: number, t: TransactionDto) => sum + t.amount, 0);

      // Procesar gastos por categoría desde el endpoint real
      const expensesByCategory = expensesAggregation.map((item: GroupedAmountDto, index: number) => {
        return {
          name: item.key || 'Sin categoría',
          value: Math.abs(item.totalAmount), // Valor absoluto para el gráfico
          color: CHART_COLORS[index % CHART_COLORS.length],
        };
      });

      // Calcular tendencias mensuales desde las transacciones reales (últimos 6 meses)
      const monthlyTrends: Array<{
        month: string;
        income: number;
        expenses: number;
      }> = [];
      for (let i = 5; i >= 0; i--) {
        const targetDate = new Date();
        targetDate.setMonth(targetDate.getMonth() - i);
        
        const monthTransactions = allTransactions.filter((t: TransactionDto) => {
          const transactionDate = new Date(t.postedAt);
          return transactionDate.getMonth() === targetDate.getMonth() &&
                 transactionDate.getFullYear() === targetDate.getFullYear();
        });

        const monthIncome = monthTransactions
          .filter((t: TransactionDto) => t.type === 'CREDIT')
          .reduce((sum: number, t: TransactionDto) => sum + t.amount, 0);

        const monthExpenses = monthTransactions
          .filter((t: TransactionDto) => t.type === 'DEBIT')
          .reduce((sum: number, t: TransactionDto) => sum + t.amount, 0);

        monthlyTrends.push({
          month: targetDate.toLocaleDateString('es-PE', { month: 'short', year: '2-digit' }),
          income: monthIncome,
          expenses: monthExpenses,
        });
      }

      setState(prev => ({
        ...prev,
        categories,
        recentTransactions,
        monthlyStats: {
          totalIncome,
          totalExpenses,
          netIncome: totalIncome - totalExpenses,
          transactionCount: monthlyTransactions.length,
        },
        expensesByCategory,
        monthlyTrends,
        isLoading: false,
      }));

    } catch (error) {
      console.error('Error loading dashboard data:', error);
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: 'Error al cargar los datos del dashboard',
      }));
    }
  }, [transactionApi]);

  // Cargar datos al montar el componente
  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  // Formatear moneda
  const formatCurrency = useCallback((amount: number) => {
    return new Intl.NumberFormat('es-PE', {
      style: 'currency',
      currency: 'PEN',
    }).format(amount);
  }, []);

  // Formatear fecha
  const formatDate = useCallback((dateString: string) => {
    return new Date(dateString).toLocaleDateString('es-PE', {
      month: 'short',
      day: 'numeric',
    });
  }, []);

  // Obtener nombre de categoría
  const getCategoryName = useCallback((categoryId?: number) => {
    if (!categoryId) return 'Sin categoría';
    const category = state.categories.find(c => c.id === categoryId);
    return category?.name || 'Sin categoría';
  }, [state.categories]);

  return (
    <div className="dashboard-page">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900">Dashboard</h1>
        <p className="text-neutral-600 mt-1">
          Resumen de tus finanzas personales
        </p>
      </div>

      {/* Estado de carga */}
      {state.isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          <span className="ml-3 text-neutral-600">Cargando dashboard...</span>
        </div>
      )}

      {/* Estado de error */}
      {state.error && (
        <div className="bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-md mb-6">
          <p>{state.error}</p>
        </div>
      )}

      {/* Contenido del dashboard */}
      {!state.isLoading && !state.error && (
        <div className="space-y-8">
          {/* Tarjetas de estadísticas */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Ingresos del mes */}
            <div className="card">
              <div className="flex items-center">
                <div className="p-3 bg-success-100 rounded-lg">
                  <ArrowTrendingUpIcon className="h-6 w-6 text-success-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-neutral-600">Ingresos del mes</p>
                  <p className="text-2xl font-bold text-success-600">
                    {formatCurrency(state.monthlyStats.totalIncome)}
                  </p>
                </div>
              </div>
            </div>

            {/* Gastos del mes */}
            <div className="card">
              <div className="flex items-center">
                <div className="p-3 bg-error-100 rounded-lg">
                  <ArrowTrendingDownIcon className="h-6 w-6 text-error-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-neutral-600">Gastos del mes</p>
                  <p className="text-2xl font-bold text-error-600">
                    {formatCurrency(state.monthlyStats.totalExpenses)}
                  </p>
                </div>
              </div>
            </div>

            {/* Balance neto */}
            <div className="card">
              <div className="flex items-center">
                <div className={clsx(
                  'p-3 rounded-lg',
                  state.monthlyStats.netIncome >= 0 ? 'bg-success-100' : 'bg-error-100'
                )}>
                  <CurrencyDollarIcon className={clsx(
                    'h-6 w-6',
                    state.monthlyStats.netIncome >= 0 ? 'text-success-600' : 'text-error-600'
                  )} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-neutral-600">Balance neto</p>
                  <p className={clsx(
                    'text-2xl font-bold',
                    state.monthlyStats.netIncome >= 0 ? 'text-success-600' : 'text-error-600'
                  )}>
                    {formatCurrency(state.monthlyStats.netIncome)}
                  </p>
                </div>
              </div>
            </div>

            {/* Transacciones */}
            <div className="card">
              <div className="flex items-center">
                <div className="p-3 bg-primary-100 rounded-lg">
                  <CalendarIcon className="h-6 w-6 text-primary-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-neutral-600">Transacciones</p>
                  <p className="text-2xl font-bold text-primary-600">
                    {state.monthlyStats.transactionCount}
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Gráficos */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Gráfico de pie - Gastos por categoría */}
            <div className="card">
              <div className="border-b border-neutral-200 px-6 py-4">
                <h3 className="text-lg font-semibold text-neutral-900 flex items-center">
                  <ChartPieIcon className="h-5 w-5 mr-2" />
                  Gastos por Categoría
                </h3>
              </div>
              <div className="p-6">
                {state.expensesByCategory.length > 0 ? (
                  <div className="h-80">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={state.expensesByCategory}
                          cx="50%"
                          cy="50%"
                          outerRadius={80}
                          fill="#8884d8"
                          dataKey="value"
                        >
                          {state.expensesByCategory.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip formatter={(value) => formatCurrency(Number(value))} />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <div className="text-center py-12">
                    <ChartPieIcon className="mx-auto h-12 w-12 text-neutral-400" />
                    <h4 className="mt-2 text-sm font-medium text-neutral-900">Sin datos</h4>
                    <p className="mt-1 text-sm text-neutral-500">
                      No hay gastos registrados para mostrar.
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* Gráfico de barras - Tendencias mensuales */}
            <div className="card">
              <div className="border-b border-neutral-200 px-6 py-4">
                <h3 className="text-lg font-semibold text-neutral-900">
                  Tendencias Mensuales
                </h3>
              </div>
              <div className="p-6">
                {state.monthlyTrends.length > 0 ? (
                  <div className="h-80">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={state.monthlyTrends}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="month" />
                        <YAxis />
                        <Tooltip formatter={(value) => formatCurrency(Number(value))} />
                        <Legend />
                        <Bar dataKey="income" fill="#10b981" name="Ingresos" />
                        <Bar dataKey="expenses" fill="#ef4444" name="Gastos" />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <div className="text-center py-12">
                    <CalendarIcon className="mx-auto h-12 w-12 text-neutral-400" />
                    <h4 className="mt-2 text-sm font-medium text-neutral-900">Sin datos</h4>
                    <p className="mt-1 text-sm text-neutral-500">
                      No hay suficientes datos para mostrar tendencias.
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Transacciones recientes */}
          <div className="card">
            <div className="border-b border-neutral-200 px-6 py-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-neutral-900">
                  Transacciones Recientes
                </h3>
                <a 
                  href="/transactions" 
                  className="text-sm text-primary-600 hover:text-primary-800"
                >
                  Ver todas
                </a>
              </div>
            </div>
            <div className="divide-y divide-neutral-200">
              {state.recentTransactions.length > 0 ? (
                state.recentTransactions.map((transaction) => (
                  <div key={transaction.id} className="px-6 py-4 flex items-center justify-between">
                    <div className="flex items-center">
                      <div className={clsx(
                        'p-2 rounded-lg',
                        transaction.type === 'CREDIT' ? 'bg-success-100' : 'bg-error-100'
                      )}>
                        {transaction.type === 'CREDIT' ? (
                          <ArrowTrendingUpIcon className="h-5 w-5 text-success-600" />
                        ) : (
                          <ArrowTrendingDownIcon className="h-5 w-5 text-error-600" />
                        )}
                      </div>
                      <div className="ml-4">
                        <p className="text-sm font-medium text-neutral-900">
                          {transaction.description}
                        </p>
                        <p className="text-sm text-neutral-500">
                          {getCategoryName(transaction.categoryId)} • {formatDate(transaction.postedAt)}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className={clsx(
                        'text-sm font-semibold',
                        transaction.type === 'CREDIT' ? 'text-success-600' : 'text-error-600'
                      )}>
                        {transaction.type === 'CREDIT' ? '+' : '-'}{formatCurrency(transaction.amount)}
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="px-6 py-12 text-center">
                  <CurrencyDollarIcon className="mx-auto h-12 w-12 text-neutral-400" />
                  <h4 className="mt-2 text-sm font-medium text-neutral-900">Sin transacciones</h4>
                  <p className="mt-1 text-sm text-neutral-500">
                    No hay transacciones recientes para mostrar.
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;