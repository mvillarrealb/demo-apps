"""
Servicio base para extracción de metadatos de bases de datos.
Define la interfaz común para todos los proveedores de base de datos.
"""
from abc import ABC, abstractmethod
from typing import Dict, Any, List
import logging

logger = logging.getLogger(__name__)

class DatabaseMetadataService(ABC):
    """Clase base abstracta para servicios de extracción de metadatos"""
    
    def __init__(self, connection):
        self.connection = connection
    
    @abstractmethod
    def get_database_indexes_query(self) -> str:
        """Retorna la consulta SQL para obtener índices de la base de datos"""
        pass
    
    @abstractmethod
    def get_table_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de tablas"""
        pass
    
    @abstractmethod
    def get_foreign_key_metadata_query(self) -> str:
        """Retorna la consulta SQL para obtener metadatos de claves foráneas"""
        pass
    
    @abstractmethod
    def get_function_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de funciones"""
        pass
    
    @abstractmethod
    def get_table_row_count_query(self) -> str:
        """Retorna la consulta SQL para obtener conteos de filas de tablas"""
        pass
    
    @abstractmethod
    def get_view_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de vistas"""
        pass
    
    @abstractmethod
    def get_trigger_definitions_query(self) -> str:
        """Retorna la consulta SQL para obtener definiciones de triggers"""
        pass
    
    @abstractmethod
    def _get_specific_vendor_metadata(self, cursor) -> Dict[str, Any]:
        """Obtiene metadatos específicos del proveedor de base de datos"""
        pass
    
    def execute_query(self, query: str, query_name: str) -> List[Dict[str, Any]]:
        """
        Ejecuta una consulta y retorna los resultados como lista de diccionarios.
        
        Args:
            query (str): Consulta SQL a ejecutar
            query_name (str): Nombre descriptivo de la consulta para logging
            
        Returns:
            List[Dict[str, Any]]: Lista de diccionarios con los resultados
        """
        try:
            with self.connection.cursor() as cursor:
                cursor.execute(query)
                columns = [desc[0] for desc in cursor.description]
                results = []
                for row in cursor.fetchall():
                    results.append(dict(zip(columns, row)))
                
                logger.debug(f"Query {query_name} executed successfully, {len(results)} rows returned")
                return results
                
        except Exception as e:
            logger.error(f"Error executing query {query_name}: {e}")
            return []
    
    def extract_all_metadata(self) -> Dict[str, Any]:
        """
        Extrae todos los metadatos de la base de datos.
        
        Returns:
            Dict[str, Any]: Diccionario con todos los metadatos extraídos
        """
        metadata = {}
        
        try:
            with self.connection.cursor() as cursor:
                # Metadatos del proveedor
                metadata['vendor_info'] = self._get_specific_vendor_metadata(cursor)
                
                # Metadatos de tablas
                metadata['tables'] = self.execute_query(
                    self.get_table_metadata_query(), 
                    "Table Metadata"
                )
                
                # Índices
                metadata['indexes'] = self.execute_query(
                    self.get_database_indexes_query(), 
                    "Database Indexes"
                )
                
                # Claves foráneas
                metadata['foreign_keys'] = self.execute_query(
                    self.get_foreign_key_metadata_query(), 
                    "Foreign Keys"
                )
                
                # Funciones
                metadata['functions'] = self.execute_query(
                    self.get_function_definitions_query(), 
                    "Function Definitions"
                )
                
                # Conteos de filas
                metadata['row_counts'] = self.execute_query(
                    self.get_table_row_count_query(), 
                    "Table Row Counts"
                )
                
                # Vistas
                metadata['views'] = self.execute_query(
                    self.get_view_definitions_query(), 
                    "View Definitions"
                )
                
                # Triggers
                metadata['triggers'] = self.execute_query(
                    self.get_trigger_definitions_query(), 
                    "Trigger Definitions"
                )
                
                return metadata
                
        except Exception as e:
            logger.error(f"Error extracting metadata: {e}")
            return metadata
    
    def get_metadata_summary(self, metadata: Dict[str, Any]) -> Dict[str, int]:
        """
        Genera un resumen de los metadatos extraídos.
        
        Args:
            metadata (Dict[str, Any]): Metadatos extraídos
            
        Returns:
            Dict[str, int]: Resumen con conteos
        """
        return {
            'tables': len(metadata.get('tables', [])),
            'indexes': len(metadata.get('indexes', [])),
            'foreign_keys': len(metadata.get('foreign_keys', [])),
            'functions': len(metadata.get('functions', [])),
            'views': len(metadata.get('views', [])),
            'triggers': len(metadata.get('triggers', []))
        }
    
    def get_database_info(self) -> Dict[str, Any]:
        """Obtiene información general de la base de datos"""
        try:
            with self.connection.cursor() as cursor:
                return self._get_specific_vendor_metadata(cursor)
        except Exception as e:
            logger.error(f"Error getting database info: {e}")
            return {}
    
    def get_table_metadata(self) -> List[Dict[str, Any]]:
        """Obtiene metadatos de todas las tablas"""
        return self.execute_query(self.get_table_metadata_query(), "Table Metadata")
    
    def get_database_indexes(self) -> List[Dict[str, Any]]:
        """Obtiene información de todos los índices"""
        return self.execute_query(self.get_database_indexes_query(), "Database Indexes")
    
    def get_foreign_key_metadata(self) -> List[Dict[str, Any]]:
        """Obtiene metadatos de claves foráneas"""
        return self.execute_query(self.get_foreign_key_metadata_query(), "Foreign Keys")
    
    def get_function_definitions(self) -> List[Dict[str, Any]]:
        """Obtiene definiciones de funciones"""
        return self.execute_query(self.get_function_definitions_query(), "Function Definitions")
    
    def get_view_definitions(self) -> List[Dict[str, Any]]:
        """Obtiene definiciones de vistas"""
        return self.execute_query(self.get_view_definitions_query(), "View Definitions")
    
    def get_trigger_definitions(self) -> List[Dict[str, Any]]:
        """Obtiene definiciones de triggers"""
        return self.execute_query(self.get_trigger_definitions_query(), "Trigger Definitions")
    
    def get_table_row_count(self) -> List[Dict[str, Any]]:
        """Obtiene conteos de filas de las tablas"""
        return self.execute_query(self.get_table_row_count_query(), "Table Row Counts")
    
    def close(self):
        """Cierra la conexión a la base de datos"""
        try:
            if hasattr(self, 'connection') and self.connection:
                self.connection.close()
                logger.info("Database connection closed")
        except Exception as e:
            logger.error(f"Error closing connection: {e}")