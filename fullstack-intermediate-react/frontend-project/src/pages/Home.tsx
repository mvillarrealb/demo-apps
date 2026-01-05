import React from 'react';
import { Link } from 'react-router-dom';

const Home: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-4xl mx-auto">
        <div className="bg-white rounded-2xl shadow-xl p-8 md:p-12">
          <div className="w-20 h-20 bg-indigo-600 rounded-full flex items-center justify-center mx-auto mb-8">
            <svg
              className="w-10 h-10 text-white"
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
          
          <div className="text-center mb-8">
            <h1 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              ¡Bienvenido al Frontend Project!
            </h1>
            
            <p className="text-lg md:text-xl text-gray-600 mb-8 leading-relaxed max-w-3xl mx-auto">
              Proyecto React con TypeScript, TailwindCSS y todas las herramientas 
            modernas para el desarrollo full-stack.
          </p>

          {/* Navigation Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
            <button className="bg-indigo-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-indigo-700 transition-colors">
              Explorar Retos
            </button>
            <Link 
              to="/help" 
              className="bg-white text-indigo-600 border-2 border-indigo-600 px-8 py-3 rounded-lg font-semibold hover:bg-indigo-50 transition-colors text-center"
            >
              Centro de Ayuda
            </Link>
          </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
            <div className="bg-indigo-50 p-6 rounded-lg">
              <h3 className="font-semibold text-indigo-900 mb-2">🚀 Stack Tecnológico</h3>
              <p className="text-indigo-700 text-sm">
                React 18, TypeScript, TailwindCSS, React Router, Axios
              </p>
            </div>
            
            <div className="bg-green-50 p-6 rounded-lg">
              <h3 className="font-semibold text-green-900 mb-2">🧪 Testing</h3>
              <p className="text-green-700 text-sm">
                Vitest, React Testing Library, Jest DOM
              </p>
            </div>
            
            <div className="bg-purple-50 p-6 rounded-lg">
              <h3 className="font-semibold text-purple-900 mb-2">📋 Formularios</h3>
              <p className="text-purple-700 text-sm">
                React Hook Form, Zod Validation
              </p>
            </div>
            
            <div className="bg-orange-50 p-6 rounded-lg">
              <h3 className="font-semibold text-orange-900 mb-2">🎨 UI/UX</h3>
              <p className="text-orange-700 text-sm">
                Heroicons, TailwindCSS Components
              </p>
            </div>
          </div>
          
          <div className="mt-8 pt-8 border-t border-gray-200">
            <p className="text-gray-500 text-sm">
              Proyecto listo para implementar cualquiera de los retos full-stack
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
