const express = require('express');
const cors = require('cors');
const config = require('./config/env');
const routes = require('./routes');
const logger = require('./middlewares/logger');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

// Middlewares
app.use(cors({
  origin: config.corsOrigin,
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(logger);

// Routes
app.use('/', routes);

// Error handling middleware (debe ir al final)
app.use(errorHandler);

module.exports = app;
