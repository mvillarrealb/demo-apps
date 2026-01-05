import { defineConfig } from 'cypress'

export default defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost:5173',
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    testIsolation: true,
    video: true,
    screenshotsFolder: 'cypress/screenshots',
    videosFolder: 'cypress/videos',
    defaultCommandTimeout: 8000,
    pageLoadTimeout: 60000,
    viewportWidth: 1366,
    viewportHeight: 768,
    retries: { runMode: 2, openMode: 0 },
    env: {
      apiUrl: process.env.CYPRESS_API_URL || 'http://localhost:8080/api',
    },
    setupNodeEvents(on, config) {
      // plugins / reporters si los necesitas
      return config
    },
  },
})