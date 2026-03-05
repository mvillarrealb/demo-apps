"""
Script principal para extraer metadatos de Oracle y generar documentación.
"""
import yaml
import os
import sys
from datetime import datetime
from collections import defaultdict
from jinja2 import Environment, FileSystemLoader
import logging

# Agregar el directorio actual al path para importar módulos locales
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from logger_config import (
    setup_logging, log_start, log_success, log_error, log_info, log_warning
)
from services.oracle_metadata_service import OracleMetadataService

def load_config(config_file: str) -> dict:
    """Cargar configuración desde archivo YAML"""
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        log_error(f"Archivo de configuración no encontrado: {config_file}")
        sys.exit(1)
    except yaml.YAMLError as e:
        log_error(f"Error al leer archivo de configuración: {e}")
        sys.exit(1)

def organize_table_metadata(table_data: list) -> dict:
    """Organizar metadatos de tablas por nombre de tabla"""
    organized = defaultdict(list)
    for row in table_data:
        table_name = row['table_name']
        organized[table_name].append(row)
    return dict(organized)

def generate_documentation(metadata: dict, template_path: str, output_file: str):
    """Generar documentación usando template Jinja2"""
    try:
        log_info(f"📄 Generando documentación con template: {template_path}")
        
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
        
        log_success(f"✅ Documentación generada exitosamente: {output_file}")
        
    except Exception as e:
        log_error(f"Error al generar documentación: {e}")
        raise

def main():
    """Función principal"""
    setup_logging()
    log_start("📊 EXTRACCIÓN DE METADATOS - ORACLE")
    
    start_time = datetime.now()
    
    try:
        # Cargar configuración
        config_path = "config-oracle.yaml"
        log_info(f"📋 Cargando configuración: {config_path}")
        config = load_config(config_path)
        
        # Crear servicio de metadatos
        log_info("🔗 Conectando a Oracle...")
        metadata_service = OracleMetadataService(config['database'])
        
        log_success("✅ Conexión exitosa a Oracle")
        
        # Inicializar diccionario de metadatos
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
        log_info("📊 Extrayendo información de la base de datos...")
        metadata['database_info'] = metadata_service.get_database_info()
        log_success(f"✅ Información de BD extraída: {metadata['database_info']['vendor']}")
        
        # Extraer metadatos de tablas
        log_info("🗂️ Extrayendo metadatos de tablas...")
        table_data = metadata_service.get_table_metadata()
        metadata['table_metadata'] = organize_table_metadata(table_data)
        log_success(f"✅ Metadatos de {len(metadata['table_metadata'])} tablas extraídos")
        
        # Extraer índices
        log_info("📇 Extrayendo información de índices...")
        metadata['database_indexes'] = metadata_service.get_database_indexes()
        log_success(f"✅ {len(metadata['database_indexes'])} índices extraídos")
        
        # Extraer claves foráneas
        log_info("🔗 Extrayendo claves foráneas...")
        metadata['foreign_key_metadata'] = metadata_service.get_foreign_key_metadata()
        log_success(f"✅ {len(metadata['foreign_key_metadata'])} claves foráneas extraídas")
        
        # Extraer funciones
        log_info("⚙️ Extrayendo definiciones de funciones...")
        metadata['function_definitions'] = metadata_service.get_function_definitions()
        log_success(f"✅ {len(metadata['function_definitions'])} funciones extraídas")
        
        # Extraer vistas
        log_info("👁️ Extrayendo definiciones de vistas...")
        metadata['view_definitions'] = metadata_service.get_view_definitions()
        log_success(f"✅ {len(metadata['view_definitions'])} vistas extraídas")
        
        # Extraer triggers
        log_info("⚡ Extrayendo definiciones de triggers...")
        metadata['trigger_definitions'] = metadata_service.get_trigger_definitions()
        log_success(f"✅ {len(metadata['trigger_definitions'])} triggers extraídos")
        
        # Extraer conteos de filas
        log_info("🔢 Extrayendo conteos de filas...")
        row_counts = metadata_service.get_table_row_count()
        metadata['table_row_count'] = {row['table_name']: row['estimated_rows'] for row in row_counts}
        log_success(f"✅ Conteos de {len(metadata['table_row_count'])} tablas extraídos")
        
        # Generar documentación
        template_path = config['output']['template']
        output_file = config['output']['file']
        
        generate_documentation(metadata, template_path, output_file)
        
        # Estadísticas finales
        end_time = datetime.now()
        duration = end_time - start_time
        
        log_success("🎉 EXTRACCIÓN DE METADATOS COMPLETADA")
        log_info(f"⏱️ Tiempo total de ejecución: {duration}")
        log_info(f"📊 Estadísticas finales:")
        log_info(f"   • Tablas: {len(metadata['table_metadata'])}")
        log_info(f"   • Vistas: {len(metadata['view_definitions'])}")
        log_info(f"   • Funciones: {len(metadata['function_definitions'])}")
        log_info(f"   • Triggers: {len(metadata['trigger_definitions'])}")
        log_info(f"   • Índices: {len(metadata['database_indexes'])}")
        log_info(f"   • Claves foráneas: {len(metadata['foreign_key_metadata'])}")
        log_info(f"📄 Documentación generada: {output_file}")
        
    except Exception as e:
        log_error(f"❌ Error durante la extracción: {e}")
        sys.exit(1)
    
    finally:
        # Cerrar conexión
        try:
            metadata_service.close()
            log_info("🔒 Conexión cerrada")
        except:
            pass

if __name__ == "__main__":
    main()