# database-inserts
Minimal Python 3 project for generating database inserts for Oracle 23ai, MSSQL 2019, and PostgreSQL 12.

## Características
- ✅ Generación de datos ficticios con Faker
- ✅ Soporte para PostgreSQL, SQL Server y Oracle
- ✅ Sistema de logging estandarizado y detallado
- ✅ Manejo de errores robusto
- ✅ Entorno virtual aislado

## Requisitos
- Python 3.x
- Virtual environment recomendado

## Instalación
```bash
python3 -m venv venv
source venv/bin/activate
pip install psycopg2-binary PyYAML Faker
```

## Configuración
Ajusta las credenciales en los archivos de configuración:
- `config-postgres.yaml` - PostgreSQL
- `config-mssql.yaml` - SQL Server  
- `config-oracle.yaml` - Oracle

## Ejecución
```bash
# Activar entorno virtual
source venv/bin/activate

# Ejecutar scripts
python3 main_postgres.py
python3 main_mssql.py
python3 main_oracle.py
```

## Sistema de Logging

### Niveles de Logging
- **INFO** (por defecto): Información general del progreso
- **DEBUG**: Información detallada de cada operación
- **ERROR**: Solo errores críticos

### Ejemplo de Output (Nivel INFO)
```
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 🚀 Iniciando script de inserción de datos para PostgreSQL
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 🔗 Intentando conectar a PostgreSQL
2025-09-16 15:20:34 | INFO     | database_inserts.postgres |    Host: localhost
2025-09-16 15:20:34 | INFO     | database_inserts.postgres |    Base de datos: banking_demo
2025-09-16 15:20:34 | INFO     | database_inserts.postgres |    Usuario: postgres
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | ✅ Conexión exitosa a PostgreSQL
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 📊 Iniciando generación de datos mock...
2025-09-16 15:20:34 | INFO     | database_inserts.postgres |    Clientes a crear: 10
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 👥 Creando clientes...
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | ✅ 10 clientes creados exitosamente
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 🏦 Creando cuentas y transacciones...
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | ✅ 20 cuentas creadas
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | ✅ 110 transacciones generadas
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 💾 Guardando cambios en la base de datos...
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | ✅ Datos guardados exitosamente
2025-09-16 15:20:34 | INFO     | database_inserts.postgres | 🎉 Script completado en 0.29 segundos
```

### Cambiar Nivel de Logging
Para activar modo DEBUG (más detallado), modifica la línea en el script:
```python
# Cambiar de:
logger = setup_logger('postgres', 'INFO')

# A:
logger = setup_logger('postgres', 'DEBUG')
```

### Logging a Archivo (Opcional)
Para habilitar logging a archivo, descomenta las líneas en `logger_config.py`:
```python
# file_handler = logging.FileHandler(f'logs/{script_name}_{datetime.now().strftime("%Y%m%d")}.log')
# logger.addHandler(file_handler)
```

## Estructura
- `main_postgres.py` - Script para PostgreSQL
- `main_mssql.py` - Script para SQL Server
- `main_oracle.py` - Script para Oracle
- `config-postgres.yaml` - Configuración PostgreSQL
- `config-mssql.yaml` - Configuración SQL Server
- `config-oracle.yaml` - Configuración Oracle
- `logger_config.py` - Configuración de logging estandarizada
- `demo_debug_logging.py` - Demostración de logging DEBUG

## Datos Generados
Cada ejecución crea:
- **10 clientes** con datos ficticios realistas
- **1-3 cuentas por cliente** (checking/savings)
- **1-10 transacciones por cuenta** (deposit/withdrawal/transfer)
- **Balances aleatorios** entre $100 - $10,000
- **Transacciones aleatorias** entre $10 - $1,000
