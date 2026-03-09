import random

from database_inserts.logger_config import (
    log_connection_attempt, log_connection_success, log_connection_error,
    log_data_generation_start, log_customer_progress, log_customer_batch_complete,
    log_account_creation, log_transaction_batch, log_accounts_summary,
)


def connect(cfg, logger):
    import pyodbc
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


def insert(conn, fake, num_customers, logger):
    cur = conn.cursor()
    customer_ids = []

    log_data_generation_start(logger, num_customers)
    logger.info("👥 Creando clientes...")
    for i in range(num_customers):
        name = fake.name()
        log_customer_progress(logger, i + 1, num_customers, name)
        cur.execute(
            "INSERT INTO customer (name, address, contact, username, password) "
            "OUTPUT INSERTED.customer_id VALUES (?, ?, ?, ?, ?)",
            (name, fake.address(), fake.phone_number(), fake.user_name(), fake.password()),
        )
        customer_ids.append(cur.fetchone()[0])
    log_customer_batch_complete(logger, num_customers)

    total_accounts = total_transactions = 0
    logger.info("🏦 Creando cuentas y transacciones...")
    for cust_id in customer_ids:
        for _ in range(random.randint(1, 3)):
            acc_type = random.choice(['checking', 'savings'])
            balance = round(random.uniform(100, 10000), 2)
            cur.execute(
                "INSERT INTO account (customer_id, type, balance) "
                "OUTPUT INSERTED.account_id VALUES (?, ?, ?)",
                (cust_id, acc_type, balance),
            )
            account_id = cur.fetchone()[0]
            total_accounts += 1
            log_account_creation(logger, cust_id, acc_type, balance)

            n_tx = random.randint(1, 10)
            for _ in range(n_tx):
                cur.execute(
                    "INSERT INTO transaction (account_id, type, amount) VALUES (?, ?, ?)",
                    (account_id, random.choice(['deposit', 'withdrawal', 'transfer']),
                     round(random.uniform(10, 1000), 2)),
                )
                total_transactions += 1
            log_transaction_batch(logger, account_id, n_tx)

    log_accounts_summary(logger, total_accounts, total_transactions)
    cur.close()
