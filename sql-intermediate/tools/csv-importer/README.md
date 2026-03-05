# CSV Importer - Sistema de Importación Bancaria

## Descripción

Sistema para importar datos masivos de clientes y cuentas bancarias desde archivos CSV a base de datos PostgreSQL 12. Genera archivos SQL con sentencias INSERT siguiendo las buenas prácticas de PostgreSQL.

## Características

✅ **Procesamiento secuencial** del CSV línea por línea  
✅ **Validación exhaustiva** de datos de entrada  
✅ **Detección de duplicados** por username  
✅ **Manejo robusto de errores** con reportes detallados  
✅ **Generación de SQL optimizado** para PostgreSQL 12  
✅ **Logging completo** del proceso de importación  
✅ **Transacciones seguras** en archivos SQL generados  

## Requisitos

- Python 3.7+
- Archivo CSV con estructura específica (ver Formato CSV)

## Estructura de Archivos

```
csv-importer/
├── csv_importer.py      # Script principal
├── README.md           # Esta documentación
├── requirements.txt    # Dependencias Python
└── output/            # Directorio de salida (generado automáticamente)
    ├── customers.sql   # Inserts de clientes
    ├── accounts.sql    # Inserts de cuentas
    ├── import_errors.txt # Reporte de errores
    └── import.log      # Log detallado del proceso
```

## Formato CSV Requerido

El archivo CSV debe contener las siguientes columnas:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `customer_id` | Entero | ID único del cliente |
| `customer_name` | Texto (max 100) | Nombre completo del cliente |
| `customer_address` | Texto (max 200) | Dirección del cliente |
| `customer_contact` | Texto (max 50) | Información de contacto |
| `customer_username` | Texto (max 50) | Username único |
| `customer_password` | Texto (max 100) | Contraseña |
| `account_id` | Entero | ID único de la cuenta |
| `account_type` | Texto | Tipo de cuenta (checking, savings, premium, business) |
| `account_balance` | Decimal | Balance inicial de la cuenta |

### Ejemplo CSV:
```csv
customer_id,customer_name,customer_address,customer_contact,customer_username,customer_password,account_id,account_type,account_balance
1,Juan Pérez,Calle 123,555-1234,jperez,pass123,1,checking,1500.50
1,Juan Pérez,Calle 123,555-1234,jperez,pass123,2,savings,5000.00
```

## Uso

### 1. Ejecución Básica

```bash
python csv_importer.py /ruta/al/archivo.csv
```

### 2. Ejemplo con el archivo de datos incluido

```bash
# Desde el directorio del proyecto
python csv_importer.py ../csv-generator/data.csv
```

### 3. Verificar resultados

Los archivos se generan en el directorio `output/`:

```bash
ls -la output/
# customers.sql    - Sentencias INSERT para tabla customer
# accounts.sql     - Sentencias INSERT para tabla account  
# import_errors.txt - Reporte detallado de errores
# import.log       - Log completo del proceso
```

## Validaciones Implementadas

### Datos de Cliente
- ✅ `customer_id` debe ser entero válido
- ✅ `customer_name` es obligatorio (max 100 caracteres)
- ✅ `customer_username` es obligatorio y único (max 50 caracteres)
- ✅ `customer_password` es obligatorio (max 100 caracteres)
- ✅ `customer_address` opcional, truncado a 200 caracteres
- ✅ `customer_contact` opcional, truncado a 50 caracteres

### Datos de Cuenta
- ✅ `account_id` debe ser entero válido
- ✅ `customer_id` debe corresponder a un cliente válido
- ✅ `account_type` debe ser uno de: checking, savings, premium, business
- ✅ `account_balance` debe ser decimal válido y no negativo

### Integridad de Datos
- ✅ Detección de usernames duplicados
- ✅ Verificación de tipos de cuenta válidos
- ✅ Validación de balances no negativos
- ✅ Escape de caracteres especiales en SQL

## Manejo de Errores

El sistema continúa procesando ante errores no críticos y genera reportes detallados:

### Tipos de Error
- `customer_validation`: Errores en datos de cliente
- `account_validation`: Errores en datos de cuenta
- `duplicate_username`: Username duplicado detectado

### Formato de Reporte
```
Línea 15 - duplicate_username: Username duplicado: jperez
Datos: {'customer_id': '2', 'customer_name': 'José Pérez', ...}
```

## Archivos SQL Generados

### customers.sql
```sql
-- customers.sql
-- Archivo generado automáticamente el 2025-09-17 10:30:00
-- Total de clientes únicos: 84

BEGIN;

INSERT INTO customer (customer_id, name, address, contact, username, password) VALUES
    (1, 'Gustavo Oliveras', 'Alameda de Atilio Carballo 26...', '+34 941 46 53 29', 'sanaya', 'm4qOx)w0^AE2'),
    (2, 'Verónica Acosta', 'Rambla de Ignacio Benitez 50...', '297-301-6986x1787', 'eugeniacanovas', '^)300OdI$&)(');

COMMIT;
```

### accounts.sql
```sql
-- accounts.sql  
-- Archivo generado automáticamente el 2025-09-17 10:30:00
-- Total de cuentas: 141

BEGIN;

INSERT INTO account (account_id, customer_id, type, balance) VALUES
    (1, 1, 'checking', 6910.80),
    (2, 2, 'premium', 194859.73);

COMMIT;
```

## Buenas Prácticas Implementadas

### PostgreSQL 12
- ✅ Uso de transacciones explícitas (BEGIN/COMMIT)
- ✅ Escape apropiado de caracteres especiales
- ✅ Tipos de datos específicos (DECIMAL para balances)
- ✅ Comentarios en archivos SQL generados
- ✅ Validación de constraints antes de INSERT

### Rendimiento
- ✅ Procesamiento línea por línea (memoria eficiente)
- ✅ INSERTs agrupados en una sola sentencia
- ✅ Validación temprana de datos

### Mantenibilidad
- ✅ Código modular y bien documentado
- ✅ Logging detallado para troubleshooting
- ✅ Manejo robusto de excepciones
- ✅ Configuración centralizada

## Estadísticas de Ejemplo

```
Estadísticas finales: {
    'total_rows': 141,
    'processed_rows': 141, 
    'unique_customers': 84,
    'total_accounts': 141,
    'errors': 0
}
```

## Solución de Problemas

### Error: "Headers faltantes en CSV"
**Causa**: El archivo CSV no tiene todas las columnas requeridas  
**Solución**: Verificar que el CSV contenga todos los campos especificados

### Error: "Username duplicado"
**Causa**: El mismo username aparece en múltiples filas  
**Solución**: Revisar el reporte de errores y corregir duplicados en origen

### Error: "Tipo de cuenta inválido"
**Causa**: `account_type` no es uno de los tipos válidos  
**Solución**: Verificar que solo se usen: checking, savings, premium, business

### Error: "Balance negativo no permitido"
**Causa**: `account_balance` tiene valor negativo  
**Solución**: Revisar y corregir balances en el archivo CSV

## Contacto y Soporte

Para reportar problemas o solicitar mejoras, revisar los logs en `output/import.log` y el reporte de errores en `output/import_errors.txt`.