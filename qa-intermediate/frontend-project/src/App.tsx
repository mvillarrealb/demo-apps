import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Home from './pages/Home';
import Dashboard from './pages/Dashboard';
import Transactions from './pages/Transactions';
import HelpComponent from './components/HelpComponent';

const App: React.FC = () => {
  return (
    <Router>
      <div className="App min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        {/* Header de navegación modernizado */}
        <nav className="bg-white/90 backdrop-blur-md border-b border-gray-200 shadow-lg sticky top-0 z-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16">
              <div className="flex items-center">
                <Link to="/" className="text-xl font-bold bg-gradient-to-r from-indigo-600 to-blue-600 bg-clip-text text-transparent hover:scale-105 transition-all duration-300 drop-shadow-sm">
                  ✨ FinanceApp
                </Link>
                <div className="hidden md:ml-10 md:flex md:space-x-2">
                  <Link 
                    to="/" 
                    className="text-gray-700 hover:text-indigo-600 hover:bg-indigo-50 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 transform hover:scale-105 hover:shadow-md"
                  >
                    🏠 Inicio
                  </Link>
                  <Link 
                    to="/dashboard" 
                    className="text-gray-700 hover:text-indigo-600 hover:bg-indigo-50 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 transform hover:scale-105 hover:shadow-md"
                  >
                    📊 Dashboard
                  </Link>
                  <Link 
                    to="/transactions" 
                    className="text-gray-700 hover:text-indigo-600 hover:bg-indigo-50 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 transform hover:scale-105 hover:shadow-md"
                  >
                    💳 Transacciones
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </nav>

        {/* Contenido principal */}
        <main className="flex-1">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/transactions" element={<Transactions />} />
            <Route path="/help" element={<HelpComponent />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
};

export default App;
