import yaml
import pyodbc
from faker import Faker
import random
import time
from logger_config import (
    setup_logger, log_connection_attempt, log_connection_success, log_connection_error,
    log_data_generation_start, log_customer_progress, log_customer_batch_complete,
    log_account_creation, log_transaction_batch, log_accounts_summary,
    log_commit_start, log_commit_success, log_script_completion, log_script_error
)

def load_config():
    """Carga la configuración desde el archivo YAML."""
    with open('config-mssql.yaml') as f:
        return yaml.safe_load(f)['db']

def connect_db(cfg, logger):
    """Establece conexión con SQL Server con logging detallado."""
    log_connection_attempt(logger, "SQL Server", cfg['host'], cfg['database'], cfg['user'])
    
    try:
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={cfg['host']},{cfg['port']};"
            f"DATABASE={cfg['database']};"
            f"UID={cfg['user']};PWD={cfg['password']}"
        )
        conn = pyodbc.connect(conn_str)
        log_connection_success(logger, "SQL Server")
        return conn
    except Exception as e:
        log_connection_error(logger, "SQL Server", e)
        raise

def main():
    # Configurar logging
    logger = setup_logger('mssql', 'INFO')  # Cambiar a 'DEBUG' para más detalle
    start_time = time.time()
    
    try:
        logger.info("🚀 Iniciando script de inserción de datos para SQL Server")
        
        # Cargar configuración y conectar
        cfg = load_config()
        conn = connect_db(cfg, logger)
        cur = conn.cursor()
        fake = Faker()

        # Configuración de datos a generar
        num_customers = 10
        log_data_generation_start(logger, num_customers)

        # Insertar clientes
        customer_ids = []
        logger.info("👥 Creando clientes...")
        for i in range(num_customers):
            customer_name = fake.name()
            log_customer_progress(logger, i + 1, num_customers, customer_name)
            
            cur.execute("""
                INSERT INTO customer (name, address, contact, username, password)
                OUTPUT INSERTED.customer_id
                VALUES (?, ?, ?, ?, ?)
            """, (customer_name, fake.address(), fake.phone_number(), fake.user_name(), fake.password()))
            customer_ids.append(cur.fetchone()[0])

        log_customer_batch_complete(logger, num_customers)

        # Insertar cuentas y transacciones
        logger.info("🏦 Creando cuentas y transacciones...")
        total_accounts = 0
        total_transactions = 0
        
        for cust_id in customer_ids:
            num_accounts = random.randint(1, 3)
            for _ in range(num_accounts):
                account_type = random.choice(['checking', 'savings'])
                balance = round(random.uniform(100, 10000), 2)
                
                cur.execute("""
                    INSERT INTO account (customer_id, type, balance)
                    OUTPUT INSERTED.account_id
                    VALUES (?, ?, ?)
                """, (cust_id, account_type, balance))
                account_id = cur.fetchone()[0]
                total_accounts += 1
                
                log_account_creation(logger, cust_id, account_type, balance)
                
                # Crear transacciones para esta cuenta
                num_transactions = random.randint(1, 10)
                for _ in range(num_transactions):
                    cur.execute("""
                        INSERT INTO transaction (account_id, type, amount)
                        VALUES (?, ?, ?)
                    """, (account_id, random.choice(['deposit', 'withdrawal', 'transfer']), round(random.uniform(10, 1000), 2)))
                    total_transactions += 1
                
                log_transaction_batch(logger, account_id, num_transactions)

        log_accounts_summary(logger, total_accounts, total_transactions)

        # Confirmar cambios
        log_commit_start(logger)
        conn.commit()
        log_commit_success(logger)
        
        # Cerrar conexiones
        cur.close()
        conn.close()
        
        # Log de finalización
        duration = time.time() - start_time
        log_script_completion(logger, duration)
        
    except Exception as e:
        log_script_error(logger, e)
        raise

if __name__ == '__main__':
    main()

if __name__ == '__main__':
    main()
