import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import HelpComponent from './components/HelpComponent';

const App: React.FC = () => {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/help" element={<HelpComponent />} />
        </Routes>
      </div>
    </Router>
  );
};

export default App;
