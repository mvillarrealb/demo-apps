import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import App from './App';

describe('App', () => {
  it('renders welcome message', () => {
    render(<App />);
    expect(screen.getByText(/Bienvenido al Frontend Project/i)).toBeInTheDocument();
  });

  it('displays stack technology information', () => {
    render(<App />);
    expect(screen.getByText(/Stack Tecnológico/i)).toBeInTheDocument();
    expect(screen.getByText(/React 18, TypeScript, TailwindCSS/i)).toBeInTheDocument();
  });
});
