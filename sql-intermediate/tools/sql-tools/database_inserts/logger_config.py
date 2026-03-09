"""
Configuración de logging estandarizada para los scripts de database-inserts.
Proporciona logging consistente con diferentes niveles y formato unificado.
"""
import logging
import sys
from datetime import datetime

def setup_logger(script_name: str, log_level: str = 'INFO') -> logging.Logger:
    """
    Configura y retorna un logger estandarizado para los scripts.
    
    Args:
        script_name (str): Nombre del script (ej: 'postgres', 'mssql', 'oracle')
        log_level (str): Nivel de logging ('DEBUG', 'INFO', 'WARNING', 'ERROR')
    
    Returns:
        logging.Logger: Logger configurado
    """
    # Crear logger específico para el script
    logger = logging.getLogger(f'database_inserts.{script_name}')
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # Evitar duplicar handlers si ya están configurados
    if logger.handlers:
        return logger
    
    # Crear formateador con timestamp, nivel, script y mensaje
    formatter = logging.Formatter(
        '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # Handler para consola
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(getattr(logging, log_level.upper()))
    console_handler.setFormatter(formatter)
    
    # Handler para archivo (opcional, comentado por defecto)
    # file_handler = logging.FileHandler(f'logs/{script_name}_{datetime.now().strftime("%Y%m%d")}.log')
    # file_handler.setLevel(logging.DEBUG)
    # file_handler.setFormatter(formatter)
    
    # Agregar handlers al logger
    logger.addHandler(console_handler)
    # logger.addHandler(file_handler)  # Descomenta si quieres logging a archivo
    
    return logger

def log_connection_attempt(logger: logging.Logger, db_type: str, host: str, database: str, user: str):
    """Log de intento de conexión a base de datos."""
    logger.info(f"🔗 Intentando conectar a {db_type}")
    logger.info(f"   Host: {host}")
    logger.info(f"   Base de datos: {database}")
    logger.info(f"   Usuario: {user}")

def log_connection_success(logger: logging.Logger, db_type: str):
    """Log de conexión exitosa."""
    logger.info(f"✅ Conexión exitosa a {db_type}")

def log_connection_error(logger: logging.Logger, db_type: str, error: Exception):
    """Log de error de conexión."""
    logger.error(f"❌ Error conectando a {db_type}: {str(error)}")

def log_data_generation_start(logger: logging.Logger, customers: int):
    """Log de inicio de generación de datos."""
    logger.info(f"📊 Iniciando generación de datos mock...")
    logger.info(f"   Clientes a crear: {customers}")

def log_customer_progress(logger: logging.Logger, current: int, total: int, customer_name: str):
    """Log de progreso de creación de clientes."""
    logger.debug(f"👤 Creando cliente {current}/{total}: {customer_name}")

def log_customer_batch_complete(logger: logging.Logger, total: int):
    """Log de finalización de creación de clientes."""
    logger.info(f"✅ {total} clientes creados exitosamente")

def log_account_creation(logger: logging.Logger, customer_id: int, account_type: str, balance: float):
    """Log de creación de cuenta."""
    logger.debug(f"🏦 Cuenta {account_type} creada para cliente {customer_id} con balance ${balance:.2f}")

def log_transaction_batch(logger: logging.Logger, account_id: int, transaction_count: int):
    """Log de lote de transacciones."""
    logger.debug(f"💳 {transaction_count} transacciones creadas para cuenta {account_id}")

def log_accounts_summary(logger: logging.Logger, total_accounts: int, total_transactions: int):
    """Log resumen de cuentas y transacciones."""
    logger.info(f"✅ {total_accounts} cuentas creadas")
    logger.info(f"✅ {total_transactions} transacciones generadas")

def log_commit_start(logger: logging.Logger):
    """Log de inicio de commit."""
    logger.info("💾 Guardando cambios en la base de datos...")

def log_commit_success(logger: logging.Logger):
    """Log de commit exitoso."""
    logger.info("✅ Datos guardados exitosamente")

def log_script_completion(logger: logging.Logger, duration: float):
    """Log de finalización del script."""
    logger.info(f"🎉 Script completado en {duration:.2f} segundos")

def log_script_error(logger: logging.Logger, error: Exception):
    """Log de error general del script."""
    logger.error(f"💥 Error ejecutando script: {str(error)}")
    logger.error("   Revisa la configuración de conexión y que la base de datos esté disponible")