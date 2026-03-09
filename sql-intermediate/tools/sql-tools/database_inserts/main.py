"""
Script principal unificado para insertar datos de prueba en diferentes vendors (PostgreSQL, SQL Server, Oracle).
Uso: uv run db-insert --vendor [postgres|mssql|oracle]
"""
import sys
import argparse
from pathlib import Path

import yaml
from faker import Faker
import time

from database_inserts.logger_config import (
    setup_logger, log_commit_start, log_commit_success,
    log_script_completion, log_script_error,
)
from database_inserts.vendors import postgres, mssql, oracle

_PACKAGE_DIR = Path(__file__).parent

# ---------------------------------------------------------------------------
# Mapeo de vendors
# ---------------------------------------------------------------------------
VENDOR_CONFIG = {
    'postgres': {
        'config_file': _PACKAGE_DIR / 'config-postgres.yaml',
        'display_name': 'PostgreSQL',
        'vendor': postgres,
    },
    'mssql': {
        'config_file': _PACKAGE_DIR / 'config-mssql.yaml',
        'display_name': 'SQL Server',
        'vendor': mssql,
    },
    'oracle': {
        'config_file': _PACKAGE_DIR / 'config-oracle.yaml',
        'display_name': 'Oracle',
        'vendor': oracle,
    },
}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Inserta datos de prueba en bases de datos bancarias.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  uv run db-insert --vendor postgres
  uv run db-insert --vendor mssql
  uv run db-insert --vendor oracle
        """
    )
    parser.add_argument(
        '--vendor', '-v',
        type=str,
        required=True,
        choices=list(VENDOR_CONFIG.keys()),
        help='Tipo de base de datos: postgres, mssql, oracle',
    )
    parser.add_argument(
        '--customers', '-n',
        type=int,
        default=10,
        help='Número de clientes a generar (default: 10)',
    )
    return parser.parse_args()


# ---------------------------------------------------------------------------
# Helpers comunes
# ---------------------------------------------------------------------------
def load_config(config_file: Path, logger):
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)['db']
    except FileNotFoundError:
        logger.error(f"❌ Archivo de configuración no encontrado: {config_file}")
        sys.exit(1)
    except (KeyError, Exception) as e:
        logger.error(f"❌ Error al leer configuración: {e}")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
def main():
    args = parse_arguments()
    vcfg = VENDOR_CONFIG[args.vendor]

    logger = setup_logger(args.vendor, 'INFO')
    start_time = time.time()

    try:
        logger.info(f"🚀 Iniciando inserción de datos para {vcfg['display_name']}")

        cfg = load_config(vcfg['config_file'], logger)
        vendor = vcfg['vendor']
        conn = vendor.connect(cfg, logger)

        vendor.insert(conn, Faker(), args.customers, logger)

        log_commit_start(logger)
        conn.commit()
        log_commit_success(logger)
        conn.close()

        log_script_completion(logger, time.time() - start_time)

    except Exception as e:
        log_script_error(logger, e)
        raise


if __name__ == '__main__':
    main()
