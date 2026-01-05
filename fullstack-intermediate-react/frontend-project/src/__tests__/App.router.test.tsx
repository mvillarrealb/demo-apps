import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { describe, it, expect } from 'vitest'
import App from '../App'

// Helper function to render with router
const renderWithRouter = (component: React.ReactElement) => {
  return render(component, { wrapper: BrowserRouter })
}

describe('App Router', () => {
  it('renders Home component on root path', () => {
    render(<App />)
    
    // Check if home page content is rendered
    expect(screen.getByText('¡Bienvenido al Frontend Project!')).toBeInTheDocument()
    expect(screen.getByText('Centro de Ayuda')).toBeInTheDocument()
  })

  it('contains navigation link to help page', () => {
    render(<App />)
    
    // Check if the help link exists
    const helpLink = screen.getByRole('link', { name: /centro de ayuda/i })
    expect(helpLink).toBeInTheDocument()
    expect(helpLink).toHaveAttribute('href', '/help')
  })
})
