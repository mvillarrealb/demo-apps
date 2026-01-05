import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect } from 'vitest'
import HelpComponent from '../components/HelpComponent'

describe('HelpComponent', () => {
  it('renders help page content correctly', () => {
    render(
      <MemoryRouter>
        <HelpComponent />
      </MemoryRouter>
    )
    
    // Check if help page content is rendered
    expect(screen.getByText('Centro de Ayuda')).toBeInTheDocument()
    expect(screen.getByText('Preguntas Frecuentes')).toBeInTheDocument()
    expect(screen.getByText('Enlaces Útiles')).toBeInTheDocument()
    expect(screen.getByText('¿Cómo empezar?')).toBeInTheDocument()
  })

  it('contains back navigation link', () => {
    render(
      <MemoryRouter>
        <HelpComponent />
      </MemoryRouter>
    )
    
    // Check if the back link exists
    const backLink = screen.getByRole('link', { name: /volver al inicio/i })
    expect(backLink).toBeInTheDocument()
    expect(backLink).toHaveAttribute('href', '/')
  })

  it('contains external documentation links', () => {
    render(
      <MemoryRouter>
        <HelpComponent />
      </MemoryRouter>
    )
    
    // Check external links
    expect(screen.getByRole('link', { name: /documentación de react/i })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /tailwindcss docs/i })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /react router/i })).toBeInTheDocument()
  })
})
