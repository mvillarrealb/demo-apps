"""
Servicio de extracción de metadatos para Oracle.
Implementa todas las consultas específicas para Oracle.
"""
import cx_Oracle
import logging
from typing import Dict, Any
from .database_metadata_service import DatabaseMetadataService

logger = logging.getLogger(__name__)

class OracleMetadataService(DatabaseMetadataService):
    """Servicio de extracción de metadatos para Oracle"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.connection = self._create_connection()
        super().__init__(self.connection)
    
    def _create_connection(self):
        """Crear conexión a Oracle"""
        try:
            service_name = self.config.get('service_name', 'ORCL')
            dsn = cx_Oracle.makedsn(self.config['host'], self.config['port'], service_name=service_name)
            connection = cx_Oracle.connect(self.config['user'], self.config['password'], dsn)
            connection.autocommit = True
            return connection
        except Exception as e:
            logger.error(f"Error connecting to Oracle: {e}")
            raise
    
    def get_database_indexes_query(self) -> str:
        """Retorna la consulta SQL para obtener índices de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          i.owner AS schema,
          i.table_name,
          i.index_name,
          i.index_type,
          i.uniqueness,
          LISTAGG(ic.column_name, ', ') WITHIN GROUP (ORDER BY ic.column_position) AS columns
        FROM all_indexes i
        LEFT JOIN all_ind_columns ic ON i.owner = ic.index_owner AND i.index_name = ic.index_name
        WHERE i.owner = '{schema}'
        GROUP BY i.owner, i.table_name, i.index_name, i.index_type, i.uniqueness
        ORDER BY i.table_name, i.index_name
        """
    
    def get_table_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de tablas de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          table_name,
          column_name,
          data_type,
          nullable AS is_nullable,
          data_default AS column_default,
          column_id AS ordinal_position,
          data_length AS character_maximum_length,
          data_precision AS numeric_precision,
          data_scale AS numeric_scale
        FROM all_tab_columns
        WHERE owner = '{schema}'
        ORDER BY table_name, column_id
        """
    
    def get_foreign_key_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de claves foráneas de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          c.owner AS schema_from,
          c.table_name AS table_from,
          cc.column_name AS column_from,
          r.owner AS schema_to,
          r.table_name AS table_to,
          rc.column_name AS column_to,
          c.constraint_name
        FROM all_constraints c
        JOIN all_cons_columns cc ON c.owner = cc.owner AND c.constraint_name = cc.constraint_name
        JOIN all_constraints r ON c.r_owner = r.owner AND c.r_constraint_name = r.constraint_name
        JOIN all_cons_columns rc ON r.owner = rc.owner AND r.constraint_name = rc.constraint_name 
                                   AND cc.position = rc.position
        WHERE c.constraint_type = 'R' AND c.owner = '{schema}'
        ORDER BY c.table_name, c.constraint_name
        """
    
    def get_function_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de funciones de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          o.owner AS schema,
          o.object_name AS function_name,
          o.object_type AS function_type,
          LISTAGG(s.text, '') WITHIN GROUP (ORDER BY s.line) AS function_definition
        FROM all_objects o
        LEFT JOIN all_source s ON o.owner = s.owner AND o.object_name = s.name AND o.object_type = s.type
        WHERE o.owner = '{schema}' 
          AND o.object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE')
        GROUP BY o.owner, o.object_name, o.object_type
        ORDER BY o.object_name
        """
    
    def get_table_row_count_query(self) -> str:
        """Retorna la consulta SQL para obtener conteos de filas de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          table_name,
          num_rows AS estimated_rows
        FROM all_tables
        WHERE owner = '{schema}'
        ORDER BY table_name
        """
    
    def get_view_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de vistas de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          view_name,
          text AS view_definition,
          'YES' AS is_updatable
        FROM all_views
        WHERE owner = '{schema}'
        ORDER BY view_name
        """
    
    def get_trigger_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de triggers de Oracle"""
        schema = self.config.get('schema', self.config['user'].upper())
        return f"""
        SELECT
          trigger_name,
          table_name,
          trigger_type,
          triggering_event,
          trigger_body AS trigger_definition,
          status
        FROM all_triggers
        WHERE owner = '{schema}'
        ORDER BY table_name, trigger_name
        """
    
    def _get_specific_vendor_metadata(self, cursor) -> Dict[str, Any]:
        """Obtiene metadatos específicos de Oracle"""
        try:
            cursor.execute("SELECT * FROM v$version WHERE banner LIKE 'Oracle%'")
            version_info = cursor.fetchone()[0]
            
            cursor.execute("SELECT sys_context('USERENV', 'DB_NAME') FROM dual")
            current_db = cursor.fetchone()[0]
            
            cursor.execute("SELECT USER FROM dual")
            current_user = cursor.fetchone()[0]
            
            return {
                'vendor': 'Oracle Database',
                'version': version_info,
                'database': current_db,
                'user': current_user,
                'driver_name': 'cx_Oracle',
                'driver_version': cx_Oracle.__version__,
                'schema': self.config.get('schema', self.config['user'].upper())
            }
        except Exception as e:
            logger.error(f"Error getting Oracle metadata: {e}")
            return {
                'vendor': 'Oracle Database',
                'version': 'Unknown',
                'database': 'Unknown',
                'user': 'Unknown',
                'driver_name': 'cx_Oracle',
                'driver_version': 'Unknown',
                'schema': self.config.get('schema', self.config['user'].upper())
            }
    
    def __del__(self):
        """Cerrar conexión cuando el objeto es destruido"""
        if hasattr(self, 'connection') and self.connection:
            try:
                self.connection.close()
            except:
                pass