export class GooglePage {
  // Elements
  searchBox = () => cy.get('[name="q"]')
  searchButton = () => cy.get('[name="btnK"]').first()
  resultStats = () => cy.get('#result-stats')

  // Actions
  visit() {
    cy.visit('https://www.google.com')
    cy.title().should('contain', 'Google')
  }

  search(query: string) {
    this.searchBox().clear().type(query)
    this.searchButton().click()
  }

  verifySearchResults() {
    this.resultStats().should('be.visible')
  }
}