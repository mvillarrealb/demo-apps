import { GooglePage } from '../../support/pageObjects/GooglePage'

const googlePage = new GooglePage()

describe('Google Basic Tests - Hola Mundo', () => {
  beforeEach(() => {
    // Configuración básica antes de cada prueba
  })

  it('debe abrir Google correctamente', () => {
    // Arrange
    cy.visit('https://www.google.com')
    
    // Assert
    cy.title().should('contain', 'Google')
    cy.get('[name="q"]').should('be.visible')
  })

  it('debe realizar una búsqueda básica usando Page Object', () => {
    // Arrange
    googlePage.visit()
    
    // Act
    googlePage.search('Cypress testing')
    
    // Assert
    googlePage.verifySearchResults()
    cy.url().should('include', 'search')
  })

  it('debe usar custom command visitGoogle', () => {
    // Act
    cy.visitGoogle()
    
    // Assert
    cy.get('[name="q"]').should('be.visible')
  })
})