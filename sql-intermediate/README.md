# Ejercicios SQL Github Copilot - Nivel Intermedio

Este repositorio contiene una serie de desafíos SQL de nivel intermedio diseñados para practicar con GitHub Copilot en un entorno bancario realista. Los ejercicios están basados en un modelo de datos completo que simula las operaciones principales de un sistema bancario.

## Modelo de Negocio

El sistema bancario maneja las siguientes entidades principales:

- **Clientes (customers)**: Personas que poseen cuentas en el banco
- **Cuentas (accounts)**: Productos bancarios asociados a los clientes
- **Beneficiarios (beneficiaries)**: Terceros registrados para transferencias
- **Transacciones (transactions)**: Movimientos financieros en las cuentas

## Contenido del Repositorio

```
📁 copilot-challenges-sql-intermediate/
├── 📄 README.md                    # Documentación principal
├── 📁 tables/                      # Esquemas de base de datos
│   ├── 📄 MSSQL_2019.sql          # Esquema para SQL Server 2019
│   ├── 📄 ORACLE_23AI.sql         # Esquema para Oracle 23c
│   └── 📄 POSTGRESQL_12.sql       # Esquema para PostgreSQL 12+
├── 📁 templates/                   # Plantillas de documentación
│   └── 📄 INSTRUCTIONS_TEMPLATE.md # Template para instrucciones
└── 📁 tools/                       # Herramientas de desarrollo
    ├── 📁 database-inserts/        # Generador de datos sintéticos
    ├── 📁 database-metadata/       # Extractor de metadatos
    └── 📁 csv-generator/           # Generador de archivos CSV
```

### Esquemas de Base de Datos

Los archivos en la carpeta `tables/` contienen el modelo de datos completo para diferentes motores:

- **PostgreSQL 12+**: Incluye tipos ENUM, comentarios en columnas y constraints avanzados
- **SQL Server 2019**: Adaptado con tipos de datos específicos de SQL Server
- **Oracle 23c**: Optimizado para características de Oracle más recientes

### Herramientas Disponibles

1. **database-inserts**: Genera datos sintéticos realistas para poblar las tablas
2. **database-metadata**: Extrae metadatos del esquema y genera documentación
3. **csv-generator**: Crea archivos CSV con datos bancarios de prueba

# Retos Disponibles

Los siguientes desafíos están diseñados para ser resueltos con la asistencia de GitHub Copilot, progresando desde operaciones básicas hasta implementaciones complejas.

## Importación de Datos desde archivo plano

### Historia de Usuario
**Como** administrador del sistema bancario  
**Quiero** importar datos masivos de clientes desde archivos CSV  
**Para** migrar información existente al nuevo sistema de manera eficiente  

### Contexto del Negocio
El banco necesita migrar datos de clientes desde sistemas legacy que exportan información en formato CSV. Los archivos contienen información básica de clientes y sus cuentas asociadas.

### Criterios de Aceptación

**Escenario 1: Importación exitosa de clientes**
- **Dado** un archivo CSV con datos válidos de clientes
- **Cuando** ejecuto el proceso de importación
- **Entonces** todos los registros se insertan correctamente en la tabla `customer`
- **Y** se generan los `customer_id` automáticamente
- **Y** se valida la unicidad del `username`

**Escenario 2: Manejo de duplicados**
- **Dado** un archivo CSV que contiene usernames duplicados
- **Cuando** intento importar los datos
- **Entonces** el sistema rechaza los registros duplicados
- **Y** continúa procesando los registros válidos
- **Y** genera un reporte de errores

**Escenario 3: Importación de cuentas asociadas**
- **Dado** un archivo CSV con datos de clientes y cuentas
- **Cuando** ejecuto la importación
- **Entonces** se crean las relaciones correctas entre `customer` y `account`
- **Y** se respetan los tipos de cuenta válidos
- **Y** los balances iniciales se establecen correctamente

# Creación de Consultas

## 1. Consulta de Saldo Actualizado

### Historia de Usuario
**Como** oficial de cuentas  
**Quiero** consultar el saldo real de una cuenta considerando todas las transacciones  
**Para** proporcionar información precisa a los clientes sobre su estado financiero  

### Contexto del Negocio
Los clientes requieren información actualizada de sus saldos. El saldo en la tabla `account` puede no reflejar las últimas transacciones, por lo que se necesita calcular el saldo real basado en el histórico de movimientos.

### Criterios de Aceptación

**Escenario 1: Cálculo de saldo con transacciones**
- **Dado** una cuenta con saldo inicial de $1000
- **Y** transacciones de depósito por $500 y retiro por $200
- **Cuando** consulto el saldo actualizado
- **Entonces** el sistema calcula: saldo_inicial + depósitos - retiros
- **Y** muestra el saldo real de $1300

**Escenario 2: Cuenta sin transacciones**
- **Dado** una cuenta sin movimientos posteriores a su creación
- **Cuando** consulto el saldo actualizado
- **Entonces** el saldo mostrado es igual al balance de la tabla `account`

**Escenario 3: Múltiples tipos de transacción**
- **Dado** una cuenta con depósitos, retiros y transferencias
- **Cuando** genero el reporte de saldo
- **Entonces** se consideran todos los tipos de `transaction_type`
- **Y** se muestra el desglose por tipo de movimiento

## 2. Consulta de Saldos Negativos (Saldo de transacciones vs saldo de tabla accounts)

### Historia de Usuario
**Como** auditor financiero  
**Quiero** identificar discrepancias entre el saldo registrado y el saldo calculado  
**Para** detectar inconsistencias en el sistema y tomar acciones correctivas  

### Contexto del Negocio
Es crítico mantener la integridad de los datos financieros. Las discrepancias entre el saldo almacenado y el calculado pueden indicar errores en el sistema, transacciones no procesadas o problemas de concurrencia.

### Criterios de Aceptación

**Escenario 1: Detección de saldos negativos**
- **Dado** cuentas con más retiros que depósitos + saldo inicial
- **Cuando** ejecuto la consulta de auditoría
- **Entonces** identifica todas las cuentas con saldo calculado negativo
- **Y** muestra la diferencia entre saldo registrado vs calculado

**Escenario 2: Reporte de discrepancias**
- **Dado** cuentas con inconsistencias entre balance y transacciones
- **Cuando** genero el reporte de auditoría
- **Entonces** lista todas las cuentas con diferencias > $0.01
- **Y** incluye información del cliente y tipo de cuenta
- **Y** calcula el monto total de discrepancias

**Escenario 3: Cuentas con sobregiros**
- **Dado** cuentas que permiten saldos negativos
- **Cuando** analizo los saldos calculados
- **Entonces** distingue entre sobregiros autorizados y errores del sistema
- **Y** marca las cuentas que requieren revisión manual

# Expansión del Modelo

## 1. Crear tabla de créditos

### Historia de Usuario
**Como** gerente de productos crediticios  
**Quiero** registrar y gestionar los créditos otorgados a los clientes  
**Para** llevar un control detallado de los préstamos y su estado de pago  

### Contexto del Negocio
El banco necesita expandir sus servicios para incluir productos crediticios. Se requiere una tabla que gestione préstamos personales, hipotecarios y comerciales, manteniendo la trazabilidad con las cuentas existentes.

### Criterios de Aceptación

**Escenario 1: Estructura de tabla de créditos**
- **Dado** la necesidad de gestionar créditos
- **Cuando** diseño la tabla `credit`
- **Entonces** incluye: credit_id, customer_id, account_id, credit_type, amount, interest_rate, term_months, status, created_date
- **Y** establece relaciones FK con `customer` y `account`
- **Y** define constraints para importes y tasas válidas

**Escenario 2: Tipos de crédito**
- **Dado** diferentes productos crediticios del banco
- **Cuando** defino los tipos de crédito
- **Entonces** incluye: 'personal', 'mortgage', 'commercial', 'auto'
- **Y** cada tipo tiene rangos de monto específicos
- **Y** tasas de interés diferenciadas por tipo

**Escenario 3: Estados del crédito**
- **Dado** el ciclo de vida de un préstamo
- **Cuando** establezco los estados posibles
- **Entonces** incluye: 'pending', 'approved', 'active', 'completed', 'defaulted'
- **Y** define las transiciones válidas entre estados

## 2. Crear tabla de calificaciones de crédito

### Historia de Usuario
**Como** analista de riesgo crediticio  
**Quiero** mantener un historial de calificaciones crediticias de los clientes  
**Para** evaluar la elegibilidad y condiciones de nuevos créditos  

### Contexto del Negocio
La evaluación crediticia es fundamental para minimizar riesgos. Se necesita una tabla que almacene el historial de calificaciones, scores y factores que influyen en la decisión crediticia.

### Criterios de Aceptación

**Escenario 1: Estructura de calificaciones**
- **Dado** la necesidad de evaluar riesgo crediticio
- **Cuando** diseño la tabla `credit_rating`
- **Entonces** incluye: rating_id, customer_id, score, rating_scale, evaluation_date, valid_until, notes
- **Y** establece FK con la tabla `customer`
- **Y** incluye constraints para rangos de score válidos

**Escenario 2: Escalas de calificación**
- **Dado** diferentes metodologías de scoring
- **Cuando** defino las escalas de rating
- **Entonces** soporta escalas: 'FICO' (300-850), 'INTERNAL' (1-10), 'BUREAU' (A-E)
- **Y** cada escala tiene interpretaciones específicas
- **Y** se valida consistencia entre score y escala

**Escenario 3: Historial de evaluaciones**
- **Dado** múltiples evaluaciones de un cliente en el tiempo
- **Cuando** consulto el historial crediticio
- **Entonces** muestra la evolución del score
- **Y** identifica la calificación vigente
- **Y** incluye notas explicativas de cambios significativos

# Creación de Store Procedures

## 1. Apertura de Cuentas

### Historia de Usuario
**Como** ejecutivo de cuenta  
**Quiero** un procedimiento automatizado para abrir nuevas cuentas  
**Para** garantizar que se siguen todos los pasos reglamentarios y se mantiene la integridad de datos  

### Contexto del Negocio
La apertura de cuentas debe seguir un proceso estandarizado que incluye validaciones, asignación de números de cuenta únicos y configuración inicial según el tipo de producto.

### Criterios de Aceptación

**Escenario 1: Apertura exitosa de cuenta**
- **Dado** un cliente existente con datos válidos
- **Cuando** ejecuto `sp_open_account(customer_id, account_type, initial_deposit)`
- **Entonces** se crea una nueva cuenta con `account_id` único
- **Y** se establece el saldo inicial con el depósito
- **Y** se registra una transacción de tipo 'deposit' inicial

**Escenario 2: Validaciones de negocio**
- **Dado** parámetros de entrada para apertura
- **Cuando** el procedimiento valida los datos
- **Entonces** verifica que el cliente existe y está activo
- **Y** valida que el tipo de cuenta es permitido
- **Y** confirma que el depósito inicial cumple el mínimo requerido

**Escenario 3: Manejo de errores**
- **Dado** datos inválidos o violaciones de reglas
- **Cuando** ocurre un error durante la apertura
- **Entonces** se realiza rollback de la transacción
- **Y** se retorna un código de error específico
- **Y** se registra el intento en logs de auditoría

## 2. Manejo de Depósitos

### Historia de Usuario
**Como** cajero del banco  
**Quiero** un procedimiento seguro para procesar depósitos  
**Para** actualizar saldos y mantener un registro preciso de todas las transacciones  

### Contexto del Negocio
Los depósitos deben actualizarse en tiempo real, manteniendo la consistencia entre la tabla de cuentas y el registro de transacciones.

### Criterios de Aceptación

**Escenario 1: Depósito exitoso**
- **Dado** una cuenta activa y un monto válido
- **Cuando** ejecuto `sp_process_deposit(account_id, amount, description)`
- **Entonces** se incrementa el balance de la cuenta
- **Y** se registra una transacción con tipo 'deposit'
- **Y** se actualiza el timestamp de última actividad

**Escenario 2: Validaciones de depósito**
- **Dado** una solicitud de depósito
- **Cuando** se validan los parámetros
- **Entonces** confirma que la cuenta existe y está activa
- **Y** verifica que el monto es positivo y dentro de límites
- **Y** valida que no excede límites diarios de depósito

**Escenario 3: Transaccionalidad**
- **Dado** un proceso de depósito en curso
- **Cuando** ocurre cualquier error durante la ejecución
- **Entonces** se revierte completamente la operación
- **Y** el saldo permanece sin cambios
- **Y** no se crea registro de transacción

## 3. Manejo de Retiros

### Historia de Usuario
**Como** cajero del banco  
**Quiero** un procedimiento seguro para procesar retiros  
**Para** validar fondos disponibles y mantener la integridad de los saldos  

### Contexto del Negocio
Los retiros requieren validaciones estrictas de fondos disponibles y límites de retiro, manteniendo la consistencia de datos.

### Criterios de Aceptación

**Escenario 1: Retiro exitoso**
- **Dado** una cuenta con fondos suficientes
- **Cuando** ejecuto `sp_process_withdrawal(account_id, amount, description)`
- **Entonces** se reduce el balance de la cuenta
- **Y** se registra una transacción con tipo 'withdrawal'
- **Y** se valida que el saldo no quede negativo

**Escenario 2: Validación de fondos**
- **Dado** una solicitud de retiro
- **Cuando** se verifica la disponibilidad de fondos
- **Entonces** compara el monto con el saldo disponible
- **Y** considera límites de retiro diarios/mensuales
- **Y** valida que la cuenta permite retiros

**Escenario 3: Fondos insuficientes**
- **Dado** un retiro que excede el saldo disponible
- **Cuando** se intenta procesar la operación
- **Entonces** se rechaza la transacción
- **Y** se retorna un mensaje de error específico
- **Y** se registra el intento fallido para auditoría

## 4. Manejo de Calificaciones y aprobación

### Historia de Usuario
**Como** analista de crédito  
**Quiero** un procedimiento automatizado para evaluar solicitudes crediticias  
**Para** aplicar criterios consistentes y acelerar el proceso de aprobación  

### Contexto del Negocio
La evaluación crediticia debe considerar múltiples factores: historial del cliente, ingresos, score crediticio y políticas internas del banco.

### Criterios de Aceptación

**Escenario 1: Evaluación automática**
- **Dado** una solicitud de crédito completa
- **Cuando** ejecuto `sp_evaluate_credit(customer_id, credit_amount, credit_type)`
- **Entonces** calcula el score basado en historial de transacciones
- **Y** consulta calificaciones crediticias existentes
- **Y** aplica reglas de negocio específicas por tipo de crédito

**Escenario 2: Aprobación automática**
- **Dado** un cliente con excelente historial crediticio
- **Y** una solicitud dentro de límites pre-aprobados
- **Cuando** se evalúa la solicitud
- **Entonces** se aprueba automáticamente
- **Y** se actualiza el estado a 'approved'
- **Y** se notifica al área comercial

**Escenario 3: Revisión manual requerida**
- **Dado** una solicitud que no cumple criterios automáticos
- **Cuando** se completa la evaluación inicial
- **Entonces** se marca para revisión manual
- **Y** se asigna a un analista senior
- **Y** se establece un plazo máximo de resolución

# Creación de Índices

## 1. Índices para Cliente

### Historia de Usuario
**Como** desarrollador de aplicaciones bancarias  
**Quiero** optimizar las consultas frecuentes sobre datos de clientes  
**Para** mejorar el rendimiento del sistema y la experiencia del usuario  

### Contexto del Negocio
Las consultas sobre clientes son las más frecuentes en el sistema bancario. Los usuarios buscan por username, nombre y datos de contacto. El sistema debe responder en menos de 100ms para consultas básicas.

### Criterios de Aceptación

**Escenario 1: Índice para autenticación**
- **Dado** que los usuarios se autentican con username
- **Cuando** se crea el índice `idx_customer_username`
- **Entonces** las consultas `SELECT * FROM customer WHERE username = ?` ejecutan en <50ms
- **Y** se mejora significativamente el tiempo de login
- **Y** el índice es único para garantizar integridad

**Escenario 2: Índice para búsquedas por nombre**
- **Dado** que los ejecutivos buscan clientes por nombre
- **Cuando** se crea el índice `idx_customer_name`
- **Entonces** las búsquedas parciales con LIKE ejecutan eficientemente
- **Y** soporta búsquedas por apellido o nombre completo
- **Y** considera ordenamiento alfabético

**Escenario 3: Índice compuesto para reportes**
- **Dado** que se generan reportes por ubicación y fecha
- **Cuando** se crea `idx_customer_location_created`
- **Entonces** optimiza consultas que filtran por address y fecha de creación
- **Y** mejora el rendimiento de reportes geográficos
- **Y** reduce el tiempo de generación de estadísticas

## 2. Índices para Cuentas

### Historia de Usuario
**Como** administrador de base de datos  
**Quiero** optimizar las consultas sobre cuentas y transacciones  
**Para** garantizar respuesta rápida en operaciones críticas del negocio  

### Contexto del Negocio
Las consultas sobre cuentas incluyen búsquedas por cliente, tipo de cuenta y rangos de saldo. Las transacciones requieren acceso rápido por cuenta y fecha para estados de cuenta y auditorías.

### Criterios de Aceptación

**Escenario 1: Índice para relación cliente-cuenta**
- **Dado** que frecuentemente se consultan cuentas por cliente
- **Cuando** se crea el índice `idx_account_customer_id`
- **Entonces** las consultas `SELECT * FROM account WHERE customer_id = ?` son instantáneas
- **Y** mejora la carga de portafolios de clientes
- **Y** optimiza joins entre customer y account

**Escenario 2: Índice para transacciones por cuenta**
- **Dado** que se consultan transacciones por cuenta y fecha
- **Cuando** se crea `idx_transaction_account_date`
- **Entonces** optimiza consultas de estado de cuenta mensual
- **Y** acelera cálculos de saldo por períodos
- **Y** mejora auditorías por rango de fechas

**Escenario 3: Índice para tipos de cuenta**
- **Dado** que se generan reportes por tipo de producto
- **Cuando** se crea `idx_account_type_balance`
- **Entonces** optimiza consultas de cuentas por tipo y rango de saldo
- **Y** acelera reportes de cartera por producto
- **Y** mejora análisis de rentabilidad por segmento

---

## 🛠️ Herramientas de Desarrollo

Para facilitar el desarrollo y testing de estos retos, el repositorio incluye herramientas auxiliares:

### 📊 CSV Generator
Genera datos sintéticos realistas para poblar las tablas del sistema.

```bash
cd tools/csv-generator
python main.py 1000  # Genera 1000 registros
```

### 💾 Database Inserts
Inserta datos de prueba directamente en la base de datos.

```bash
cd tools/database-inserts
python main_postgres.py  # Para PostgreSQL
```

### 📋 Database Metadata
Extrae metadatos del esquema y genera documentación automática.

```bash
cd tools/database-metadata
python main.py  # Genera documentación del esquema
```

---

## 🚀 Cómo Empezar

1. **Configura tu entorno de base de datos** usando los scripts en `tables/`
2. **Genera datos de prueba** con las herramientas en `tools/`
3. **Selecciona un reto** y desarrolla la solución con GitHub Copilot
4. **Valida tu solución** contra los criterios de aceptación
5. **Optimiza** usando las métricas de rendimiento sugeridas

