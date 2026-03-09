-- MSSQL_2019.sql
-- Declaración de tablas y relaciones para SQL Server 2019 basada en el modelo entidad-relación

CREATE TABLE customer (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    address NVARCHAR(200),
    contact NVARCHAR(50),
    username NVARCHAR(50) UNIQUE NOT NULL,
    password NVARCHAR(100) NOT NULL
);
GO

EXEC sp_addextendedproperty 'MS_Description', 'Identificador único del cliente', 'SCHEMA', 'dbo', 'TABLE', 'customer', 'COLUMN', 'customer_id';
EXEC sp_addextendedproperty 'MS_Description', 'Nombre completo del cliente', 'SCHEMA', 'dbo', 'TABLE', 'customer', 'COLUMN', 'name';
EXEC sp_addextendedproperty 'MS_Description', 'Dirección del cliente', 'SCHEMA', 'dbo', 'TABLE', 'customer', 'COLUMN', 'address';
EXEC sp_addextendedproperty 'MS_Description', 'Información de contacto del cliente', 'SCHEMA', 'dbo', 'TABLE', 'customer', 'COLUMN', 'contact';
EXEC sp_addextendedproperty 'MS_Description', 'Nombre de usuario único', 'SCHEMA', 'dbo', 'TABLE', 'customer', 'COLUMN', 'username';
EXEC sp_addextendedproperty 'MS_Description', 'Contraseña encriptada del usuario', 'SCHEMA', 'dbo', 'TABLE', 'customer', 'COLUMN', 'password';
GO

CREATE TABLE account (
    account_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    type NVARCHAR(30) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
GO

EXEC sp_addextendedproperty 'MS_Description', 'Identificador único de la cuenta', 'SCHEMA', 'dbo', 'TABLE', 'account', 'COLUMN', 'account_id';
EXEC sp_addextendedproperty 'MS_Description', 'Identificador del cliente propietario', 'SCHEMA', 'dbo', 'TABLE', 'account', 'COLUMN', 'customer_id';
EXEC sp_addextendedproperty 'MS_Description', 'Tipo de cuenta bancaria', 'SCHEMA', 'dbo', 'TABLE', 'account', 'COLUMN', 'type';
EXEC sp_addextendedproperty 'MS_Description', 'Saldo actual de la cuenta', 'SCHEMA', 'dbo', 'TABLE', 'account', 'COLUMN', 'balance';
GO

CREATE TABLE beneficiary (
    beneficiary_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    account_number NVARCHAR(30) NOT NULL,
    bank_details NVARCHAR(200),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
GO

EXEC sp_addextendedproperty 'MS_Description', 'Identificador único del beneficiario', 'SCHEMA', 'dbo', 'TABLE', 'beneficiary', 'COLUMN', 'beneficiary_id';
EXEC sp_addextendedproperty 'MS_Description', 'Identificador del cliente que registra al beneficiario', 'SCHEMA', 'dbo', 'TABLE', 'beneficiary', 'COLUMN', 'customer_id';
EXEC sp_addextendedproperty 'MS_Description', 'Nombre del beneficiario', 'SCHEMA', 'dbo', 'TABLE', 'beneficiary', 'COLUMN', 'name';
EXEC sp_addextendedproperty 'MS_Description', 'Número de cuenta del beneficiario', 'SCHEMA', 'dbo', 'TABLE', 'beneficiary', 'COLUMN', 'account_number';
EXEC sp_addextendedproperty 'MS_Description', 'Detalles bancarios del beneficiario', 'SCHEMA', 'dbo', 'TABLE', 'beneficiary', 'COLUMN', 'bank_details';
GO

CREATE TYPE transaction_type AS TABLE (
    type NVARCHAR(20)
);
-- NOTA: SQL Server no soporta ENUM nativo, se recomienda usar CHECK o tabla de referencia
GO

CREATE TABLE transaction (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    account_id INT NOT NULL,
    type NVARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    timestamp DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (account_id) REFERENCES account(account_id)
);
GO

EXEC sp_addextendedproperty 'MS_Description', 'Identificador único de la transacción', 'SCHEMA', 'dbo', 'TABLE', 'transaction', 'COLUMN', 'transaction_id';
EXEC sp_addextendedproperty 'MS_Description', 'Identificador de la cuenta asociada', 'SCHEMA', 'dbo', 'TABLE', 'transaction', 'COLUMN', 'account_id';
EXEC sp_addextendedproperty 'MS_Description', 'Tipo de transacción', 'SCHEMA', 'dbo', 'TABLE', 'transaction', 'COLUMN', 'type';
EXEC sp_addextendedproperty 'MS_Description', 'Monto de la transacción', 'SCHEMA', 'dbo', 'TABLE', 'transaction', 'COLUMN', 'amount';
EXEC sp_addextendedproperty 'MS_Description', 'Fecha y hora de la transacción', 'SCHEMA', 'dbo', 'TABLE', 'transaction', 'COLUMN', 'timestamp';
GO