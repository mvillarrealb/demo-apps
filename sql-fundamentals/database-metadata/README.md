# Database Metadata Extractor

Este proyecto permite extraer metadatos completos de bases de datos PostgreSQL, SQL Server y Oracle, generando documentación automática en formato Markdown usando templates Jinja2.

## Características

- ✅ **Multi-base de datos**: Soporte para PostgreSQL, SQL Server y Oracle
- 📊 **Extracción completa**: Tablas, vistas, funciones, triggers, índices y claves foráneas
- 📄 **Documentación automática**: Genera documentación en Markdown usando templates Jinja2
- 🎯 **Logging detallado**: Sistema de logging con emojis y mensajes informativos
- 🔧 **Configuración flexible**: Archivos YAML para cada base de datos
- ⚡ **Desarrollado con uv**: Gestión moderna de dependencias y entornos virtuales
- 🐍 **Python 3.13+**: Compatibilidad con las últimas versiones de Python
- 🔄 **Drivers modernos**: psycopg 3, oracledb 2.0+, pyodbc 5.2+

## Estructura del Proyecto

```
database-metadata/
├── services/                    # Servicios de extracción por vendor
│   ├── __init__.py
│   ├── database_metadata_service.py    # Clase base abstracta
│   ├── postgres_metadata_service.py    # Servicio PostgreSQL
│   ├── mssql_metadata_service.py       # Servicio SQL Server
│   └── oracle_metadata_service.py      # Servicio Oracle
├── templates/                   # Templates Jinja2
│   └── SCHEMA_TEMPLATE.md      # Template principal de documentación
├── output/                     # Documentación generada
├── config-postgres.yaml       # Configuración PostgreSQL
├── config-mssql.yaml         # Configuración SQL Server
├── config-oracle.yaml        # Configuración Oracle
├── main_postgres_metadata.py  # Script principal PostgreSQL
├── main_mssql_metadata.py    # Script principal SQL Server
├── main_oracle_metadata.py   # Script principal Oracle
├── logger_config.py          # Configuración de logging
├── pyproject.toml            # Configuración del proyecto y dependencias
├── requirements.txt          # Dependencias Python (legacy)
└── README.md                 # Este archivo
```

## Requisitos

- **Python**: 3.13+ (recomendado 3.14)
- **uv**: Gestor de paquetes moderno para Python ([instalar uv](https://docs.astral.sh/uv/getting-started/installation/))
- **Bases de datos soportadas**:
  - PostgreSQL 12+
  - SQL Server 2019+
  - Oracle 23ai+

## Instalación

### Método 1: Usando uv (Recomendado) ⚡

```bash
# Navegar al directorio del proyecto
cd sql-fundamentals/database-metadata

# Instalar uv si no lo tienes
curl -LsSf https://astral.sh/uv/install.sh | sh
# O en macOS con Homebrew:
brew install uv

# Sincronizar dependencias y crear entorno virtual automáticamente
uv sync
```

¡Eso es todo! `uv` se encarga de:
- ✅ Crear el entorno virtual (`.venv`)
- ✅ Instalar todas las dependencias
- ✅ Resolver compatibilidades
- ✅ Gestionar el lock file

### Método 2: Usando pip (Tradicional)

```bash
# Navegar al directorio del proyecto
cd sql-fundamentals/database-metadata

# Crear virtual environment
python3 -m venv venv

# Activar virtual environment
# En macOS/Linux:
source venv/bin/activate
# En Windows:
# venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt
```

## Configuración

### PostgreSQL (config-postgres.yaml)

```yaml
database:
  host: localhost
  port: 5432
  database: banking_demo
  user: postgres
  password: PutYourPasswordHere
  schema: public

extraction:
  include_system_tables: false
  include_views: true
  include_functions: true
  include_procedures: true
  include_indexes: true
  include_foreign_keys: true

output:
  template: ./templates/SCHEMA_TEMPLATE.md
  file: ./output/postgresql_schema_documentation.md
```

### SQL Server (config-mssql.yaml)

```yaml
database:
  host: localhost
  port: 1433
  database: banking_demo
  user: sa
  password: PutYourPasswordHere
  schema: dbo

extraction:
  include_system_tables: false
  include_views: true
  include_functions: true
  include_procedures: true
  include_indexes: true
  include_foreign_keys: true

output:
  template: ./templates/SCHEMA_TEMPLATE.md
  file: ./output/sqlserver_schema_documentation.md
```

### Oracle (config-oracle.yaml)

```yaml
database:
  host: localhost
  port: 1521
  service_name: ORCL
  user: banking_user
  password: PutYourPasswordHere
  schema: BANKING_USER

extraction:
  include_system_tables: false
  include_views: true
  include_functions: true
  include_procedures: true
  include_indexes: true
  include_foreign_keys: true

output:
  template: ./templates/SCHEMA_TEMPLATE.md
  file: ./output/oracle_schema_documentation.md
```

## Uso

### 1. Configurar Conexión

Edita el archivo de configuración correspondiente a tu base de datos y actualiza los parámetros de conexión.

### 2. Ejecutar Extracción

**Con uv (Recomendado):**
```bash
# Para PostgreSQL
uv run main_postgres_metadata.py

# Para SQL Server
uv run main_mssql_metadata.py

# Para Oracle
uv run main_oracle_metadata.py
```

**Con Python tradicional:**
```bash
# Asegúrate de tener el entorno virtual activado
source venv/bin/activate  # o venv\Scripts\activate en Windows

# Para PostgreSQL
python main_postgres_metadata.py

# Para SQL Server
python main_mssql_metadata.py

# Para Oracle
python main_oracle_metadata.py
```

### 3. Revisar Documentación

La documentación generada estará disponible en la carpeta `output/` con el nombre especificado en la configuración.

## Metadatos Extraídos

### Información de Base de Datos
- Vendor y versión
- Base de datos actual
- Usuario conectado
- Driver utilizado
- Esquema objetivo

### Tablas
- Estructura de columnas (nombre, tipo, nullable, default, posición)
- Conteos estimados de filas
- Índices asociados
- Claves foráneas
- Triggers asociados

### Vistas
- Definición completa
- Información de actualización

### Funciones y Procedimientos
- Definiciones completas
- Tipo de objeto

### Índices
- Información de unicidad
- Columnas incluidas
- Tipo de índice

### Claves Foráneas
- Relaciones entre tablas
- Columnas de origen y destino

### Triggers
- Definiciones completas
- Eventos que los activan
- Estado del trigger

## Template Personalizado

El template Jinja2 (`SCHEMA_TEMPLATE.md`) puede ser personalizado para cambiar el formato de la documentación generada. El template tiene acceso a todas las variables de metadatos extraídos.

### Variables Disponibles

```jinja2
{{ metadata.database_info }}        # Información de la BD
{{ metadata.table_metadata }}       # Metadatos de tablas
{{ metadata.database_indexes }}     # Índices
{{ metadata.foreign_key_metadata }} # Claves foráneas
{{ metadata.function_definitions }} # Funciones/procedimientos
{{ metadata.view_definitions }}     # Vistas
{{ metadata.trigger_definitions }}  # Triggers
{{ metadata.table_row_count }}      # Conteos de filas
{{ metadata.generated_at }}         # Timestamp de generación
```

## Logging

El sistema incluye logging detallado con:
- 🚀 Inicio de proceso
- ✅ Operaciones exitosas
- ❌ Errores
- ℹ️ Información general
- ⚠️ Advertencias
- ⏱️ Métricas de tiempo
- 📊 Estadísticas finales

## Gestión de Dependencias con uv

### Actualizar dependencias
```bash
# Actualizar todas las dependencias a sus últimas versiones
uv lock --upgrade

# Re-sincronizar el entorno
uv sync
```

### Agregar nuevas dependencias
```bash
# Agregar una dependencia al proyecto
uv add nombre-paquete

# Agregar dependencia de desarrollo
uv add --dev nombre-paquete
```

### Remover dependencias
```bash
uv remove nombre-paquete
```

## Dependencias Modernas

Este proyecto utiliza las versiones más recientes y mantenidas de los drivers de base de datos:

- **PostgreSQL**: `psycopg[binary]>=3.2.0` (sucesor de psycopg2)
- **Oracle**: `oracledb>=2.0.0` (sucesor de cx_Oracle)
- **SQL Server**: `pyodbc>=5.2.0`
- **Template Engine**: `Jinja2>=3.1.0`
- **Config**: `PyYAML>=6.0.0`
- **UI**: `colorama>=0.4.6`

## Solución de Problemas

### Error de Conexión
- Verifica que la base de datos esté ejecutándose
- Confirma las credenciales en el archivo de configuración
- Asegúrate de que el usuario tenga permisos de lectura

### Error con uv
- Actualiza uv: `uv self update`
- Limpia cache: `uv cache clean`
- Re-sincroniza: `uv sync --reinstall`

### PostgreSQL: Error con psycopg
- psycopg 3 incluye binarios pre-compilados
- Si falla, instala dependencias del sistema: `libpq-dev` (Linux) o `postgresql` (macOS con Homebrew)

### Oracle: Error con oracledb
- **Modo Thin** (recomendado): No requiere Oracle Instant Client
- **Modo Thick**: Si necesitas Instant Client, configura `oracledb.init_oracle_client()`

### SQL Server: Error con pyodbc
- Instala ODBC Driver for SQL Server
- En Linux/macOS, instala unixODBC: `brew install unixodbc` o `apt-get install unixodbc-dev`

## Ejemplos de Salida

La documentación generada incluirá:

1. **Resumen ejecutivo** con estadísticas generales
2. **Información detallada de cada tabla** con:
   - Estructura de columnas
   - Índices asociados
   - Claves foráneas
   - Triggers
3. **Definiciones de vistas** con código SQL
4. **Funciones y procedimientos** con definiciones completas
5. **Índices consolidados** en formato tabla
6. **Relaciones entre tablas** visualizadas

## Contribución

Para contribuir al proyecto:

1. Fork del repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

## Licencia

Este proyecto está bajo la licencia MIT. Ver archivo LICENSE para más detalles.