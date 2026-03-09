-- POSTGRESQL_12.sql
-- Declaración de tablas y relaciones para el modelo entidad-relación proporcionado


CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    contact VARCHAR(50),
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL
);

COMMENT ON COLUMN customer.customer_id IS 'Identificador único del cliente';
COMMENT ON COLUMN customer.name IS 'Nombre completo del cliente';
COMMENT ON COLUMN customer.address IS 'Dirección del cliente';
COMMENT ON COLUMN customer.contact IS 'Información de contacto del cliente';
COMMENT ON COLUMN customer.username IS 'Nombre de usuario único';
COMMENT ON COLUMN customer.password IS 'Contraseña encriptada del usuario';

CREATE TABLE account (
    account_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    type VARCHAR(30) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

COMMENT ON COLUMN account.account_id IS 'Identificador único de la cuenta';
COMMENT ON COLUMN account.customer_id IS 'Identificador del cliente propietario';
COMMENT ON COLUMN account.type IS 'Tipo de cuenta bancaria';
COMMENT ON COLUMN account.balance IS 'Saldo actual de la cuenta';

CREATE TABLE beneficiary (
    beneficiary_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    account_number VARCHAR(30) NOT NULL,
    bank_details VARCHAR(200),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

COMMENT ON COLUMN beneficiary.beneficiary_id IS 'Identificador único del beneficiario';
COMMENT ON COLUMN beneficiary.customer_id IS 'Identificador del cliente que registra al beneficiario';
COMMENT ON COLUMN beneficiary.name IS 'Nombre del beneficiario';
COMMENT ON COLUMN beneficiary.account_number IS 'Número de cuenta del beneficiario';
COMMENT ON COLUMN beneficiary.bank_details IS 'Detalles bancarios del beneficiario';

CREATE TYPE transaction_type AS ENUM ('deposit', 'withdrawal', 'transfer');

CREATE TABLE transaction (
    transaction_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL,
    type transaction_type NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES account(account_id)
);

COMMENT ON COLUMN transaction.transaction_id IS 'Identificador único de la transacción';
COMMENT ON COLUMN transaction.account_id IS 'Identificador de la cuenta asociada';
COMMENT ON COLUMN transaction.type IS 'Tipo de transacción';
COMMENT ON COLUMN transaction.amount IS 'Monto de la transacción';
COMMENT ON COLUMN transaction.timestamp IS 'Fecha y hora de la transacción';