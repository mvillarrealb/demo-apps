import random

from database_inserts.logger_config import (
    log_connection_attempt, log_connection_success, log_connection_error,
    log_data_generation_start, log_customer_progress, log_customer_batch_complete,
    log_account_creation, log_transaction_batch, log_accounts_summary,
)


def connect(cfg, logger):
    import oracledb
    service_name = cfg.get('service_name', 'ORCL')
    log_connection_attempt(logger, "Oracle", cfg['host'], service_name, cfg['user'])
    try:
        dsn = oracledb.makedsn(cfg['host'], cfg['port'], service_name=service_name)
        conn = oracledb.connect(cfg['user'], cfg['password'], dsn)
        log_connection_success(logger, "Oracle")
        return conn
    except Exception as e:
        log_connection_error(logger, "Oracle", e)
        raise


def insert(conn, fake, num_customers, logger):
    import oracledb
    cur = conn.cursor()
    customer_ids = []

    log_data_generation_start(logger, num_customers)
    logger.info("👥 Creando clientes...")
    for i in range(num_customers):
        name = fake.name()
        log_customer_progress(logger, i + 1, num_customers, name)
        cid_var = cur.var(oracledb.NUMBER)
        cur.execute(
            "INSERT INTO customer (name, address, contact, username, password) "
            "VALUES (:1, :2, :3, :4, :5) RETURNING customer_id INTO :6",
            (name, fake.address(), fake.phone_number(), fake.user_name(), fake.password(), cid_var),
        )
        customer_ids.append(cid_var.getvalue()[0])
    log_customer_batch_complete(logger, num_customers)

    total_accounts = total_transactions = 0
    logger.info("🏦 Creando cuentas y transacciones...")
    for cust_id in customer_ids:
        for _ in range(random.randint(1, 3)):
            acc_type = random.choice(['checking', 'savings'])
            balance = round(random.uniform(100, 10000), 2)
            aid_var = cur.var(oracledb.NUMBER)
            cur.execute(
                "INSERT INTO account (customer_id, type, balance) "
                "VALUES (:1, :2, :3) RETURNING account_id INTO :4",
                (cust_id, acc_type, balance, aid_var),
            )
            account_id = aid_var.getvalue()[0]
            total_accounts += 1
            log_account_creation(logger, cust_id, acc_type, balance)

            n_tx = random.randint(1, 10)
            for _ in range(n_tx):
                cur.execute(
                    "INSERT INTO transaction (account_id, type, amount) VALUES (:1, :2, :3)",
                    (account_id, random.choice(['deposit', 'withdrawal', 'transfer']),
                     round(random.uniform(10, 1000), 2)),
                )
                total_transactions += 1
            log_transaction_batch(logger, account_id, n_tx)

    log_accounts_summary(logger, total_accounts, total_transactions)
    cur.close()
