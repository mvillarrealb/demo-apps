import React from 'react';

const Home: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-4xl mx-auto">
        <div className="card p-8 md:p-12">
          {/* Hero Icon */}
          <div className="w-20 h-20 bg-gradient-to-r from-indigo-600 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-8 shadow-lg transform hover:scale-105 transition-transform duration-300">
            <svg
              className="w-10 h-10 text-white animate-pulse"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
          </div>
          
          {/* Main Content */}
          <div className="text-center mb-8">
            <h1 className="text-3xl md:text-4xl font-bold bg-gradient-to-r from-indigo-600 to-blue-600 bg-clip-text text-transparent mb-4">
              Sistema de Finanzas Personales
            </h1>
            
            <p className="text-lg md:text-xl text-gray-600 mb-8 leading-relaxed max-w-3xl mx-auto">
              Gestiona tus ingresos y gastos de manera inteligente. Registra transacciones, 
              categoriza tus movimientos y visualiza tus patrones financieros.
            </p>
          </div>
          
          {/* Features Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
            <div className="stat-card bg-gradient-to-br from-blue-50 to-blue-100 border-blue-200">
              <h3 className="font-semibold text-blue-900 mb-2 flex items-center gap-2">
                <span className="text-xl">📊</span>
                Dashboard Interactivo
              </h3>
              <p className="text-blue-700 text-sm">
                Visualiza tus gastos por categoría con gráficos en tiempo real
              </p>
            </div>
            
            <div className="stat-card bg-gradient-to-br from-green-50 to-green-100 border-green-200">
              <h3 className="font-semibold text-green-900 mb-2 flex items-center gap-2">
                <span className="text-xl">💰</span>
                Gestión de Transacciones
              </h3>
              <p className="text-green-700 text-sm">
                Registra ingresos y gastos con categorización avanzada
              </p>
            </div>
            
            <div className="stat-card bg-gradient-to-br from-purple-50 to-purple-100 border-purple-200">
              <h3 className="font-semibold text-purple-900 mb-2 flex items-center gap-2">
                <span className="text-xl">🔍</span>
                Filtros Avanzados
              </h3>
              <p className="text-purple-700 text-sm">
                Busca y filtra por categoría, fechas, montos y descripción
              </p>
            </div>
            
            <div className="stat-card bg-gradient-to-br from-orange-50 to-orange-100 border-orange-200">
              <h3 className="font-semibold text-orange-900 mb-2 flex items-center gap-2">
                <span className="text-xl">📈</span>
                Análisis Financiero
              </h3>
              <p className="text-orange-700 text-sm">
                Obtén insights sobre tus patrones de gasto e ingreso
              </p>
            </div>
          </div>
          
          {/* Footer */}
          <div className="mt-8 pt-8 border-t border-gray-200">
            <p className="text-gray-500 text-sm text-center">
              Sistema completo de gestión financiera personal - Desarrollado con React, TypeScript y TailwindCSS
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
