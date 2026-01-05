"""
Servicio de extracción de metadatos para SQL Server.
Implementa todas las consultas específicas para SQL Server.
"""
import pyodbc
import logging
from typing import Dict, Any
from .database_metadata_service import DatabaseMetadataService

logger = logging.getLogger(__name__)

class MSSQLMetadataService(DatabaseMetadataService):
    """Servicio de extracción de metadatos para SQL Server"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.connection = self._create_connection()
        super().__init__(self.connection)
    
    def _create_connection(self):
        """Crear conexión a SQL Server"""
        try:
            conn_str = (
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={self.config['host']},{self.config['port']};"
                f"DATABASE={self.config['database']};"
                f"UID={self.config['user']};PWD={self.config['password']}"
            )
            connection = pyodbc.connect(conn_str)
            connection.autocommit = True
            return connection
        except Exception as e:
            logger.error(f"Error connecting to SQL Server: {e}")
            raise
    
    def get_database_indexes_query(self) -> str:
        """Retorna la consulta SQL para obtener índices de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          s.name AS schema,
          t.name AS table_name,
          i.name AS index_name,
          i.type_desc AS index_type,
          i.is_unique,
          i.is_primary_key,
          STRING_AGG(c.name, ', ') AS columns
        FROM sys.indexes i
        JOIN sys.tables t ON i.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE s.name = '{schema}' AND i.name IS NOT NULL
        GROUP BY s.name, t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
        ORDER BY t.name, i.name
        """
    
    def get_table_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de tablas de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          t.table_name,
          c.column_name,
          c.data_type,
          c.is_nullable,
          c.column_default,
          c.ordinal_position,
          c.character_maximum_length,
          c.numeric_precision,
          c.numeric_scale
        FROM information_schema.tables t
        JOIN information_schema.columns c ON t.table_name = c.table_name
        WHERE t.table_schema = '{schema}' AND t.table_type = 'BASE TABLE'
        ORDER BY t.table_name, c.ordinal_position
        """
    
    def get_foreign_key_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de claves foráneas de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          OBJECT_SCHEMA_NAME(f.parent_object_id) AS schema_from,
          OBJECT_NAME(f.parent_object_id) AS table_from,
          COL_NAME(fc.parent_object_id, fc.parent_column_id) AS column_from,
          OBJECT_SCHEMA_NAME(f.referenced_object_id) AS schema_to,
          OBJECT_NAME(f.referenced_object_id) AS table_to,
          COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS column_to,
          f.name AS constraint_name
        FROM sys.foreign_keys f
        INNER JOIN sys.foreign_key_columns fc ON f.object_id = fc.constraint_object_id
        WHERE OBJECT_SCHEMA_NAME(f.parent_object_id) = '{schema}'
        ORDER BY table_from, constraint_name
        """
    
    def get_function_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de funciones de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          s.name AS schema,
          o.name AS function_name,
          o.type_desc AS function_type,
          m.definition AS function_definition
        FROM sys.objects o
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        LEFT JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE s.name = '{schema}' 
          AND o.type IN ('FN', 'IF', 'TF', 'FS', 'FT', 'PC')
        ORDER BY o.name
        """
    
    def get_table_row_count_query(self) -> str:
        """Retorna la consulta SQL para obtener conteos de filas de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          t.name AS table_name,
          SUM(p.rows) AS estimated_rows
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.partitions p ON t.object_id = p.object_id
        WHERE s.name = '{schema}' AND p.index_id IN (0, 1)
        GROUP BY t.name
        ORDER BY t.name
        """
    
    def get_view_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de vistas de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          v.table_name AS view_name,
          m.definition AS view_definition,
          v.is_updatable
        FROM information_schema.views v
        LEFT JOIN sys.objects o ON o.name = v.table_name AND SCHEMA_NAME(o.schema_id) = v.table_schema
        LEFT JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE v.table_schema = '{schema}'
        ORDER BY v.table_name
        """
    
    def get_trigger_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de triggers de SQL Server"""
        schema = self.config.get('schema', 'dbo')
        return f"""
        SELECT
          t.name AS trigger_name,
          OBJECT_NAME(t.parent_id) AS table_name,
          t.type_desc AS trigger_type,
          m.definition AS trigger_definition,
          t.is_disabled
        FROM sys.triggers t
        LEFT JOIN sys.sql_modules m ON t.object_id = m.object_id
        JOIN sys.tables tb ON t.parent_id = tb.object_id
        JOIN sys.schemas s ON tb.schema_id = s.schema_id
        WHERE s.name = '{schema}' AND t.parent_class = 1
        ORDER BY table_name, trigger_name
        """
    
    def _get_specific_vendor_metadata(self, cursor) -> Dict[str, Any]:
        """Obtiene metadatos específicos de SQL Server"""
        try:
            cursor.execute("SELECT @@VERSION")
            version_info = cursor.fetchone()[0]
            
            cursor.execute("SELECT DB_NAME()")
            current_db = cursor.fetchone()[0]
            
            cursor.execute("SELECT SYSTEM_USER")
            current_user = cursor.fetchone()[0]
            
            return {
                'vendor': 'Microsoft SQL Server',
                'version': version_info,
                'database': current_db,
                'user': current_user,
                'driver_name': 'pyodbc',
                'driver_version': pyodbc.version,
                'schema': self.config.get('schema', 'dbo')
            }
        except Exception as e:
            logger.error(f"Error getting SQL Server metadata: {e}")
            return {
                'vendor': 'Microsoft SQL Server',
                'version': 'Unknown',
                'database': 'Unknown',
                'user': 'Unknown',
                'driver_name': 'pyodbc',
                'driver_version': 'Unknown',
                'schema': self.config.get('schema', 'dbo')
            }
    
    def __del__(self):
        """Cerrar conexión cuando el objeto es destruido"""
        if hasattr(self, 'connection') and self.connection:
            try:
                self.connection.close()
            except:
                pass