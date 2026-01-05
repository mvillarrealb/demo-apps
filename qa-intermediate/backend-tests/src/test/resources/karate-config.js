/**
 * Karate DSL - Configuración Global
 * Este archivo se ejecuta una vez antes de todas las pruebas
 * Define variables y configuraciones que estarán disponibles en todos los feature files
 */
function fn() {
  
  // Configuración base de la API
  var config = {
    // URL base de la API de JSONPlaceholder
    baseUrl: 'https://jsonplaceholder.typicode.com',
    
    // Configuración de timeouts
    timeout: 30000,
    
    // Headers por defecto
    defaultHeaders: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    
    // Datos de prueba comunes
    testData: {
      validTodoId: 1,
      invalidTodoId: 999,
      newTodo: {
        title: 'Test TODO from Karate',
        body: 'Este es un TODO de prueba creado con Karate DSL',
        userId: 1,
        completed: false
      }
    }
  };

  // Configuraciones específicas por entorno
  var env = karate.env; // Obtiene el entorno desde la variable del sistema
  
  if (!env) {
    env = 'dev'; // entorno por defecto
  }
  
  karate.log('Ejecutando en entorno:', env);
  
  switch(env) {
    case 'dev':
      config.baseUrl = 'https://jsonplaceholder.typicode.com';
      break;
    case 'staging':
      config.baseUrl = 'https://staging.jsonplaceholder.typicode.com';
      break;
    case 'prod':
      config.baseUrl = 'https://jsonplaceholder.typicode.com';
      break;
    default:
      karate.log('Entorno no reconocido:', env, 'usando configuración por defecto');
  }
  
  // Configuración de Karate
  karate.configure('connectTimeout', config.timeout);
  karate.configure('readTimeout', config.timeout);
  karate.configure('ssl', true);
  
  // Log de configuración cargada
  karate.log('Configuración cargada para entorno:', env);
  karate.log('URL base configurada:', config.baseUrl);
  
  return config;
}