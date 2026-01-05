"""
Servicio de extracción de metadatos para PostgreSQL.
Implementa todas las consultas específicas para PostgreSQL.
"""
import psycopg2
import logging
from typing import Dict, Any
from .database_metadata_service import DatabaseMetadataService

logger = logging.getLogger(__name__)

class PostgresMetadataService(DatabaseMetadataService):
    """Servicio de extracción de metadatos para PostgreSQL"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.connection = self._create_connection()
        super().__init__(self.connection)
    
    def _create_connection(self):
        """Crear conexión a PostgreSQL"""
        try:
            connection = psycopg2.connect(
                host=self.config['host'],
                port=self.config['port'],
                database=self.config['database'],
                user=self.config['user'],
                password=self.config['password']
            )
            connection.autocommit = True
            return connection
        except Exception as e:
            logger.error(f"Error connecting to PostgreSQL: {e}")
            raise
    
    def get_database_indexes_query(self) -> str:
        """Retorna la consulta SQL para obtener índices de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          schemaname AS schema,
          tablename AS table_name,
          indexname AS index_name,
          indexdef AS definition
        FROM pg_indexes 
        WHERE schemaname = '{schema}'
        ORDER BY tablename, indexname
        """
    
    def get_table_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de tablas de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          table_name,
          column_name,
          data_type,
          is_nullable,
          column_default,
          ordinal_position,
          character_maximum_length,
          numeric_precision,
          numeric_scale
        FROM information_schema.columns
        WHERE table_schema = '{schema}'
        ORDER BY table_name, ordinal_position
        """
    
    def get_foreign_key_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de claves foráneas de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          tc.table_name AS table_from,
          kcu.column_name AS column_from,
          ccu.table_name AS table_to,
          ccu.column_name AS column_to,
          tc.constraint_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = '{schema}'
        ORDER BY tc.table_name, tc.constraint_name
        """
    
    def get_function_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de funciones de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          n.nspname AS schema,
          p.proname AS function_name,
          CASE (p.prokind)
            WHEN 'f' THEN 'Function'
            WHEN 'p' THEN 'Procedure'
            WHEN 'a' THEN 'Aggregate'
            WHEN 'w' THEN 'Window'
          END as function_type,
          pg_get_functiondef(p.oid) AS function_definition,
          obj_description(p.oid) AS description
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = '{schema}' 
          AND prokind IN ('f', 'p', 'a', 'w')
        ORDER BY p.proname
        """
    
    def get_table_row_count_query(self) -> str:
        """Retorna la consulta SQL para obtener conteos de filas de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          relname AS table_name,
          reltuples::BIGINT AS estimated_rows
        FROM pg_class
        JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE nspname = '{schema}' 
          AND relkind = 'r'
        ORDER BY relname
        """
    
    def get_view_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de vistas de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          table_name AS view_name,
          view_definition,
          is_updatable,
          is_insertable_into
        FROM information_schema.views
        WHERE table_schema = '{schema}'
        ORDER BY table_name
        """
    
    def get_trigger_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de triggers de PostgreSQL"""
        schema = self.config.get('schema', 'public')
        return f"""
        SELECT
          t.trigger_name,
          t.event_manipulation,
          t.event_object_table AS table_name,
          t.action_timing,
          p.prosrc AS trigger_definition
        FROM information_schema.triggers t
        LEFT JOIN pg_proc p ON p.proname = t.trigger_name
        LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE t.trigger_schema = '{schema}'
        ORDER BY t.event_object_table, t.trigger_name
        """
    
    def _get_specific_vendor_metadata(self, cursor) -> Dict[str, Any]:
        """Obtiene metadatos específicos de PostgreSQL"""
        try:
            cursor.execute("SELECT version()")
            version_info = cursor.fetchone()[0]
            
            cursor.execute("SELECT current_database()")
            current_db = cursor.fetchone()[0]
            
            cursor.execute("SELECT current_user")
            current_user = cursor.fetchone()[0]
            
            return {
                'vendor': 'PostgreSQL',
                'version': version_info,
                'database': current_db,
                'user': current_user,
                'driver_name': 'psycopg2',
                'driver_version': psycopg2.__version__,
                'schema': self.config.get('schema', 'public')
            }
        except Exception as e:
            logger.error(f"Error getting PostgreSQL metadata: {e}")
            return {
                'vendor': 'PostgreSQL',
                'version': 'Unknown',
                'database': 'Unknown',
                'user': 'Unknown',
                'driver_name': 'psycopg2',
                'driver_version': 'Unknown',
                'schema': self.config.get('schema', 'public')
            }
    
    def __del__(self):
        """Cerrar conexión cuando el objeto es destruido"""
        if hasattr(self, 'connection') and self.connection:
            try:
                self.connection.close()
            except:
                pass