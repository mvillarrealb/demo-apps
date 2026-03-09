#!/usr/bin/env python3
"""
CSV to PostgreSQL SQL Importer
===============================

Script para importar datos de clientes y cuentas desde CSV y generar archivos SQL
siguiendo las buenas prácticas de PostgreSQL 12.

Autor: Sistema de Importación Bancaria
Fecha: Septiembre 2025
"""

import csv
import os
import sys
from datetime import datetime
from typing import Dict, List, Set, Tuple, Optional
from decimal import Decimal, InvalidOperation
import logging


class CSVImportError(Exception):
    """Excepción personalizada para errores de importación"""
    pass


class ValidationError(Exception):
    """Excepción para errores de validación de datos"""
    pass


class CSVImporter:
    """Importador de datos CSV a SQL para PostgreSQL"""
    
    # Tipos de cuenta válidos según el esquema
    VALID_ACCOUNT_TYPES = {'checking', 'savings', 'premium', 'business'}
    
    def __init__(self, csv_file_path: str, output_dir: str = './output'):
        """
        Inicializa el importador
        
        Args:
            csv_file_path: Ruta al archivo CSV
            output_dir: Directorio de salida para archivos SQL
        """
        self.csv_file_path = csv_file_path
        self.output_dir = output_dir
        self.customers: Dict[int, Dict] = {}
        self.accounts: List[Dict] = []
        self.errors: List[Dict] = []
        self.stats = {
            'total_rows': 0,
            'processed_rows': 0,
            'unique_customers': 0,
            'total_accounts': 0,
            'errors': 0
        }
        
        # Crear directorio de salida si no existe
        os.makedirs(output_dir, exist_ok=True)
        
        # Configurar logging
        self._setup_logging()
    
    def _setup_logging(self):
        """Configura el sistema de logging"""
        # Asegurar que el directorio de output existe antes de crear el log
        os.makedirs(self.output_dir, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(f'{self.output_dir}/import.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def _validate_customer_data(self, row: Dict, line_number: int) -> Optional[Dict]:
        """
        Valida los datos de un cliente
        
        Args:
            row: Fila del CSV como diccionario
            line_number: Número de línea para reporte de errores
            
        Returns:
            Diccionario con datos del cliente válidos o None si hay errores
        """
        try:
            # Validar customer_id
            customer_id = int(row['customer_id'])
            
            # Validar campos obligatorios
            required_fields = ['customer_name', 'customer_username', 'customer_password']
            for field in required_fields:
                if not row.get(field, '').strip():
                    raise ValidationError(f"Campo obligatorio vacío: {field}")
            
            # Validar longitud de username
            username = row['customer_username'].strip()
            if len(username) > 50:
                raise ValidationError(f"Username demasiado largo: {len(username)} caracteres")
            
            # Validar longitud de nombre
            name = row['customer_name'].strip()
            if len(name) > 100:
                raise ValidationError(f"Nombre demasiado largo: {len(name)} caracteres")
            
            return {
                'customer_id': customer_id,
                'name': name,
                'address': row.get('customer_address', '').strip()[:200],  # Truncar si es necesario
                'contact': row.get('customer_contact', '').strip()[:50],
                'username': username,
                'password': row['customer_password'].strip()[:100]
            }
            
        except (ValueError, ValidationError) as e:
            self._log_error(line_number, 'customer_validation', str(e), row)
            return None
    
    def _validate_account_data(self, row: Dict, line_number: int) -> Optional[Dict]:
        """
        Valida los datos de una cuenta
        
        Args:
            row: Fila del CSV como diccionario
            line_number: Número de línea para reporte de errores
            
        Returns:
            Diccionario con datos de la cuenta válidos o None si hay errores
        """
        try:
            # Validar account_id
            account_id = int(row['account_id'])
            customer_id = int(row['customer_id'])
            
            # Validar tipo de cuenta
            account_type = row.get('account_type', '').strip().lower()
            if account_type not in self.VALID_ACCOUNT_TYPES:
                raise ValidationError(f"Tipo de cuenta inválido: {account_type}")
            
            # Validar balance
            try:
                balance = Decimal(row.get('account_balance', '0'))
                if balance < 0:
                    raise ValidationError(f"Balance negativo no permitido: {balance}")
            except (InvalidOperation, ValueError):
                raise ValidationError(f"Balance inválido: {row.get('account_balance', '')}")
            
            return {
                'account_id': account_id,
                'customer_id': customer_id,
                'type': account_type,
                'balance': balance
            }
            
        except (ValueError, ValidationError) as e:
            self._log_error(line_number, 'account_validation', str(e), row)
            return None
    
    def _log_error(self, line_number: int, error_type: str, message: str, row: Dict):
        """Registra un error de validación"""
        error_record = {
            'line': line_number,
            'type': error_type,
            'message': message,
            'data': row
        }
        self.errors.append(error_record)
        self.stats['errors'] += 1
        self.logger.warning(f"Línea {line_number} - {error_type}: {message}")
    
    def process_csv(self):
        """Procesa el archivo CSV línea por línea"""
        self.logger.info(f"Iniciando procesamiento de {self.csv_file_path}")
        
        try:
            with open(self.csv_file_path, 'r', encoding='utf-8') as file:
                csv_reader = csv.DictReader(file)
                
                # Verificar headers
                expected_headers = {
                    'customer_id', 'customer_name', 'customer_address', 
                    'customer_contact', 'customer_username', 'customer_password',
                    'account_id', 'account_type', 'account_balance'
                }
                
                if not expected_headers.issubset(set(csv_reader.fieldnames)):
                    missing = expected_headers - set(csv_reader.fieldnames)
                    raise CSVImportError(f"Headers faltantes en CSV: {missing}")
                
                usernames_seen: Set[str] = set()
                line_number = 1  # Empezar en 1 porque la línea 0 son headers
                
                for row in csv_reader:
                    line_number += 1
                    self.stats['total_rows'] += 1
                    
                    # Validar datos del cliente
                    customer_data = self._validate_customer_data(row, line_number)
                    if customer_data is None:
                        continue
                    
                    # Verificar unicidad de username
                    username = customer_data['username']
                    if username in usernames_seen:
                        self._log_error(line_number, 'duplicate_username', 
                                      f"Username duplicado: {username}", row)
                        continue
                    
                    # Validar datos de la cuenta
                    account_data = self._validate_account_data(row, line_number)
                    if account_data is None:
                        continue
                    
                    # Registrar cliente (solo si es nuevo)
                    customer_id = customer_data['customer_id']
                    if customer_id not in self.customers:
                        self.customers[customer_id] = customer_data
                        usernames_seen.add(username)
                        self.stats['unique_customers'] += 1
                    
                    # Registrar cuenta
                    self.accounts.append(account_data)
                    self.stats['total_accounts'] += 1
                    self.stats['processed_rows'] += 1
                
        except FileNotFoundError:
            raise CSVImportError(f"Archivo CSV no encontrado: {self.csv_file_path}")
        except Exception as e:
            raise CSVImportError(f"Error procesando CSV: {str(e)}")
        
        self.logger.info(f"Procesamiento completado. Estadísticas: {self.stats}")
    
    def generate_customers_sql(self) -> str:
        """Genera el archivo customers.sql"""
        output_file = os.path.join(self.output_dir, 'customers.sql')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Header con metadatos
            f.write(f"""-- customers.sql
-- Archivo generado automáticamente el {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Importación de datos de clientes desde CSV
-- Total de clientes únicos: {self.stats['unique_customers']}
-- Errores encontrados: {self.stats['errors']}

-- Iniciar transacción
BEGIN;

-- Insertar datos de clientes
""")
            
            if self.customers:
                f.write("INSERT INTO customer (customer_id, name, address, contact, username, password) VALUES\n")
                
                customer_values = []
                for customer in self.customers.values():
                    # Escapar comillas simples para SQL
                    name = customer['name'].replace("'", "''")
                    address = customer['address'].replace("'", "''")
                    contact = customer['contact'].replace("'", "''")
                    username = customer['username'].replace("'", "''")
                    password = customer['password'].replace("'", "''")
                    
                    value_line = f"    ({customer['customer_id']}, '{name}', '{address}', '{contact}', '{username}', '{password}')"
                    customer_values.append(value_line)
                
                f.write(",\n".join(customer_values))
                f.write(";\n\n")
            else:
                f.write("-- No hay datos de clientes válidos para insertar\n\n")
            
            f.write("""-- Confirmar transacción
COMMIT;

-- Comentarios sobre la importación
COMMENT ON TABLE customer IS 'Tabla de clientes importada desde CSV';
""")
        
        self.logger.info(f"Archivo customers.sql generado: {output_file}")
        return output_file
    
    def generate_accounts_sql(self) -> str:
        """Genera el archivo accounts.sql"""
        output_file = os.path.join(self.output_dir, 'accounts.sql')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Header con metadatos
            f.write(f"""-- accounts.sql
-- Archivo generado automáticamente el {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Importación de datos de cuentas desde CSV
-- Total de cuentas: {self.stats['total_accounts']}
-- Errores encontrados: {self.stats['errors']}

-- Iniciar transacción
BEGIN;

-- Insertar datos de cuentas
""")
            
            if self.accounts:
                f.write("INSERT INTO account (account_id, customer_id, type, balance) VALUES\n")
                
                account_values = []
                for account in self.accounts:
                    value_line = f"    ({account['account_id']}, {account['customer_id']}, '{account['type']}', {account['balance']})"
                    account_values.append(value_line)
                
                f.write(",\n".join(account_values))
                f.write(";\n\n")
            else:
                f.write("-- No hay datos de cuentas válidos para insertar\n\n")
            
            f.write("""-- Confirmar transacción
COMMIT;

-- Comentarios sobre la importación
COMMENT ON TABLE account IS 'Tabla de cuentas importada desde CSV';
""")
        
        self.logger.info(f"Archivo accounts.sql generado: {output_file}")
        return output_file
    
    def generate_error_report(self) -> str:
        """Genera un reporte de errores"""
        output_file = os.path.join(self.output_dir, 'import_errors.txt')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(f"""REPORTE DE ERRORES DE IMPORTACIÓN
=================================
Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Archivo CSV: {self.csv_file_path}

ESTADÍSTICAS:
- Total de filas procesadas: {self.stats['total_rows']}
- Filas válidas: {self.stats['processed_rows']}
- Clientes únicos: {self.stats['unique_customers']}
- Cuentas procesadas: {self.stats['total_accounts']}
- Errores encontrados: {self.stats['errors']}

DETALLE DE ERRORES:
""")
            
            if self.errors:
                for error in self.errors:
                    f.write(f"\nLínea {error['line']} - {error['type']}: {error['message']}\n")
                    f.write(f"Datos: {error['data']}\n")
                    f.write("-" * 80 + "\n")
            else:
                f.write("No se encontraron errores durante la importación.\n")
        
        self.logger.info(f"Reporte de errores generado: {output_file}")
        return output_file
    
    def run_import(self) -> Dict[str, str]:
        """
        Ejecuta el proceso completo de importación
        
        Returns:
            Diccionario con rutas de archivos generados
        """
        try:
            # Procesar CSV
            self.process_csv()
            
            # Generar archivos SQL
            customers_file = self.generate_customers_sql()
            accounts_file = self.generate_accounts_sql()
            errors_file = self.generate_error_report()
            
            self.logger.info("Importación completada exitosamente")
            
            return {
                'customers_sql': customers_file,
                'accounts_sql': accounts_file,
                'error_report': errors_file,
                'stats': self.stats
            }
            
        except Exception as e:
            self.logger.error(f"Error durante la importación: {str(e)}")
            raise


def main():
    """Función principal"""
    if len(sys.argv) != 2:
        print("Uso: python csv_importer.py <ruta_archivo_csv>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    
    try:
        importer = CSVImporter(csv_file)
        results = importer.run_import()
        
        print("\n" + "="*60)
        print("IMPORTACIÓN COMPLETADA")
        print("="*60)
        print(f"Archivo customers.sql: {results['customers_sql']}")
        print(f"Archivo accounts.sql: {results['accounts_sql']}")
        print(f"Reporte de errores: {results['error_report']}")
        print(f"\nEstadísticas finales: {results['stats']}")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()