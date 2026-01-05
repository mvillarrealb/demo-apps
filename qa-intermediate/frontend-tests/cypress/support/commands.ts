/// <reference types="cypress" />

declare global {
  namespace Cypress {
    interface Chainable {
      getByCy(value: string): Chainable
      visitGoogle(): Chainable
    }
  }
}

Cypress.Commands.add('getByCy', (value: string) => {
  return cy.get(`[data-cy="${value}"]`)
})

Cypress.Commands.add('visitGoogle', () => {
  cy.visit('https://www.google.com')
  cy.title().should('contain', 'Google')
})

export {}