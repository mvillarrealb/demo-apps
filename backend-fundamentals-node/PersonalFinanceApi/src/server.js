const app = require('./app');
const config = require('./config/env');
const { testConnection, sequelize } = require('./config/database');

const startServer = async () => {
  try {
    // Test database connection
    await testConnection();

    // Sync database (en desarrollo, usar migraciones en producción)
    if (config.nodeEnv === 'development') {
      await sequelize.sync({ alter: false });
      console.log('✅ Database synced');
    }

    // Start server
    app.listen(config.port, () => {
      console.log(`🚀 Server running on port ${config.port}`);
      console.log(`📝 Environment: ${config.nodeEnv}`);
      console.log(`🔗 Health check: http://localhost:${config.port}/health`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
