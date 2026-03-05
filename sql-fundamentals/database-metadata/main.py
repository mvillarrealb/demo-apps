"""
Script principal unificado para extraer metadatos de diferentes vendors (PostgreSQL, Oracle, SQL Server).
Uso: python main.py --vendor [postgres|oracle|mssql]
"""
import yaml
import os
import sys
import argparse
from datetime import datetime
from collections import defaultdict
from jinja2 import Environment, FileSystemLoader
import logging

# Agregar el directorio actual al path para importar módulos locales
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from logger_config import (
    setup_logger, log_connection_attempt, log_connection_success, log_connection_error,
    log_script_completion, log_script_error
)
from services import PostgresMetadataService, OracleMetadataService, MSSQLMetadataService

# Mapeo de vendors a sus servicios y configuraciones
VENDOR_CONFIG = {
    'postgres': {
        'service_class': PostgresMetadataService,
        'config_file': 'config-postgres.yaml',
        'display_name': 'PostgreSQL'
    },
    'oracle': {
        'service_class': OracleMetadataService,
        'config_file': 'config-oracle.yaml',
        'display_name': 'Oracle'
    },
    'mssql': {
        'service_class': MSSQLMetadataService,
        'config_file': 'config-mssql.yaml',
        'display_name': 'SQL Server'
    }
}

def parse_arguments():
    """Parsear argumentos de línea de comandos"""
    parser = argparse.ArgumentParser(
        description='Extrae metadatos de bases de datos y genera documentación.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python main.py --vendor postgres
  python main.py --vendor oracle
  python main.py --vendor mssql
        """
    )
    
    parser.add_argument(
        '--vendor',
        '-v',
        type=str,
        required=True,
        choices=['postgres', 'oracle', 'mssql'],
        help='Tipo de base de datos (postgres, oracle, mssql)'
    )
    
    return parser.parse_args()

def load_config(config_file: str, logger) -> dict:
    """Cargar configuración desde archivo YAML"""
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        logger.error(f"❌ Archivo de configuración no encontrado: {config_file}")
        sys.exit(1)
    except yaml.YAMLError as e:
        logger.error(f"❌ Error al leer archivo de configuración: {e}")
        sys.exit(1)

def organize_table_metadata(table_data: list) -> dict:
    """Organizar metadatos de tablas por nombre de tabla"""
    organized = defaultdict(list)
    for row in table_data:
        table_name = row['table_name']
        organized[table_name].append(row)
    return dict(organized)

def generate_documentation(metadata: dict, template_path: str, output_file: str, logger):
    """Generar documentación usando template Jinja2"""
    try:
        logger.info(f"📄 Generando documentación con template: {template_path}")
        
        # Configurar Jinja2
        template_dir = os.path.dirname(template_path)
        template_file = os.path.basename(template_path)
        
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        
        # Renderizar template
        rendered = template.render(metadata=metadata)
        
        # Escribir archivo de salida
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(rendered)
        
        logger.info(f"✅ Documentación generada exitosamente: {output_file}")
        
    except Exception as e:
        logger.error(f"❌ Error al generar documentación: {e}")
        raise

def extract_metadata(metadata_service, logger) -> dict:
    """Extraer todos los metadatos usando el servicio proporcionado"""
    metadata = {
        'generated_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'database_info': {},
        'table_metadata': {},
        'database_indexes': [],
        'foreign_key_metadata': [],
        'function_definitions': [],
        'view_definitions': [],
        'trigger_definitions': [],
        'table_row_count': {}
    }
    
    # Extraer información de la base de datos
    logger.info("📊 Extrayendo información de la base de datos...")
    metadata['database_info'] = metadata_service.get_database_info()
    logger.info(f"✅ Información de BD extraída: {metadata['database_info']['vendor']}")
    
    # Extraer metadatos de tablas
    logger.info("🗂️ Extrayendo metadatos de tablas...")
    table_data = metadata_service.get_table_metadata()
    metadata['table_metadata'] = organize_table_metadata(table_data)
    logger.info(f"✅ Metadatos de {len(metadata['table_metadata'])} tablas extraídos")
    
    # Extraer índices
    logger.info("📇 Extrayendo información de índices...")
    metadata['database_indexes'] = metadata_service.get_database_indexes()
    logger.info(f"✅ {len(metadata['database_indexes'])} índices extraídos")
    
    # Extraer claves foráneas
    logger.info("🔗 Extrayendo claves foráneas...")
    metadata['foreign_key_metadata'] = metadata_service.get_foreign_key_metadata()
    logger.info(f"✅ {len(metadata['foreign_key_metadata'])} claves foráneas extraídas")
    
    # Extraer funciones
    logger.info("⚙️ Extrayendo definiciones de funciones...")
    metadata['function_definitions'] = metadata_service.get_function_definitions()
    logger.info(f"✅ {len(metadata['function_definitions'])} funciones extraídas")
    
    # Extraer vistas
    logger.info("👁️ Extrayendo definiciones de vistas...")
    metadata['view_definitions'] = metadata_service.get_view_definitions()
    logger.info(f"✅ {len(metadata['view_definitions'])} vistas extraídas")
    
    # Extraer triggers
    logger.info("⚡ Extrayendo definiciones de triggers...")
    metadata['trigger_definitions'] = metadata_service.get_trigger_definitions()
    logger.info(f"✅ {len(metadata['trigger_definitions'])} triggers extraídos")
    
    # Extraer conteos de filas
    logger.info("🔢 Extrayendo conteos de filas...")
    row_counts = metadata_service.get_table_row_count()
    metadata['table_row_count'] = {row['table_name']: row['estimated_rows'] for row in row_counts}
    logger.info(f"✅ Conteos de {len(metadata['table_row_count'])} tablas extraídos")
    
    return metadata

def print_statistics(metadata: dict, output_file: str, duration: float, logger):
    """Imprimir estadísticas finales"""
    logger.info("🎉 EXTRACCIÓN DE METADATOS COMPLETADA")
    logger.info(f"⏱️ Tiempo total de ejecución: {duration:.2f} segundos")
    logger.info(f"📊 Estadísticas finales:")
    logger.info(f"   • Tablas: {len(metadata['table_metadata'])}")
    logger.info(f"   • Vistas: {len(metadata['view_definitions'])}")
    logger.info(f"   • Funciones: {len(metadata['function_definitions'])}")
    logger.info(f"   • Triggers: {len(metadata['trigger_definitions'])}")
    logger.info(f"   • Índices: {len(metadata['database_indexes'])}")
    logger.info(f"   • Claves foráneas: {len(metadata['foreign_key_metadata'])}")
    logger.info(f"📄 Documentación generada: {output_file}")

def main():
    """Función principal"""
    # Parsear argumentos
    args = parse_arguments()
    vendor = args.vendor
    
    # Validar vendor y obtener configuración
    if vendor not in VENDOR_CONFIG:
        print(f"❌ Vendor no soportado: {vendor}")
        print(f"Vendors disponibles: {', '.join(VENDOR_CONFIG.keys())}")
        sys.exit(1)
    
    vendor_info = VENDOR_CONFIG[vendor]
    display_name = vendor_info['display_name']
    
    # Configurar logger
    logger = setup_logger(f'{vendor}_metadata')
    logger.info(f"🚀 Iniciando extracción de metadatos - {display_name}")
    
    start_time = datetime.now()
    metadata_service = None
    
    try:
        # Cargar configuración
        config_file = vendor_info['config_file']
        logger.info(f"📋 Cargando configuración: {config_file}")
        config = load_config(config_file, logger)
        
        # Crear servicio de metadatos usando el servicio correcto
        log_connection_attempt(logger, display_name, 
                              config['database'].get('host', 'N/A'), 
                              config['database'].get('database', config['database'].get('service_name', 'N/A')), 
                              config['database']['user'])
        
        service_class = vendor_info['service_class']
        metadata_service = service_class(config['database'])
        log_connection_success(logger, display_name)
        
        # Extraer metadatos
        metadata = extract_metadata(metadata_service, logger)
        
        # Generar documentación
        template_path = config['output']['template']
        output_file = config['output']['file']
        generate_documentation(metadata, template_path, output_file, logger)
        
        # Estadísticas finales
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        print_statistics(metadata, output_file, duration, logger)
        log_script_completion(logger, duration)
        
    except Exception as e:
        log_script_error(logger, e)
        sys.exit(1)
    
    finally:
        # Cerrar conexión
        if metadata_service is not None:
            try:
                metadata_service.close()
                logger.info("🔒 Conexión cerrada")
            except Exception as e:
                logger.warning(f"⚠️ Error al cerrar conexión: {e}")

if __name__ == "__main__":
    main()
