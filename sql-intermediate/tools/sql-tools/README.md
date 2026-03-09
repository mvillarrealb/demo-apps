# sql-tools

Proyecto unificado con herramientas SQL para generación e importación de datos bancarios sintéticos.

## Herramientas incluidas

| Comando | Descripción |
|---|---|
| `csv-generate <N>` | Genera un CSV con N registros sintéticos (clientes + cuentas) |
| `csv-import <archivo.csv>` | Importa un CSV y genera archivos SQL listos para ejecutar |
| `db-insert-postgres` | Inserta datos de prueba en PostgreSQL |
| `db-insert-mssql` | Inserta datos de prueba en SQL Server |
| `db-insert-oracle` | Inserta datos de prueba en Oracle |

## Uso

```bash
# Instalar el entorno
uv sync

# Generar 1000 registros CSV
uv run csv-generate 1000

# Importar CSV y generar SQL
uv run csv-import data.csv

# Insertar datos en base de datos (requiere configurar config-*.yaml)
uv run db-insert-postgres
uv run db-insert-mssql
uv run db-insert-oracle
```

## Configuración

Los archivos de conexión se encuentran en `database_inserts/`:

- `config-postgres.yaml` — PostgreSQL
- `config-mssql.yaml` — SQL Server
- `config-oracle.yaml` — Oracle
