#!/usr/bin/env python3
"""
CSV Generator para sistema bancario
Genera datos sintéticos combinando información de customer y account
basado en el modelo de datos PostgreSQL adjunto.

Uso: python main.py <numero_de_lineas>
Ejemplo: python main.py 1000
"""

import sys
import csv
import random
from faker import Faker
from typing import List, Dict

# Configurar Faker para datos en español/latino
fake = Faker(['es_ES', 'es_MX'])

def generate_customer_data() -> Dict[str, str]:
    """
    Genera datos para un cliente basado en la tabla customer
    """
    first_name = fake.first_name()
    last_name = fake.last_name()
    full_name = f"{first_name} {last_name}"
    
    return {
        'customer_id': '',  # Se asignará secuencialmente
        'name': full_name,
        'address': fake.address().replace('\n', ', '),
        'contact': fake.phone_number(),
        'username': fake.user_name(),
        'password': fake.password(length=12, special_chars=True, digits=True, upper_case=True)
    }

def generate_account_data(customer_id: int) -> Dict[str, str]:
    """
    Genera datos para una cuenta bancaria basado en la tabla account
    """
    account_types = ['savings', 'checking', 'business', 'premium']
    
    # Generar balance realista según el tipo de cuenta
    account_type = random.choice(account_types)
    if account_type == 'business':
        balance = round(random.uniform(5000, 100000), 2)
    elif account_type == 'premium':
        balance = round(random.uniform(10000, 250000), 2)
    elif account_type == 'savings':
        balance = round(random.uniform(100, 50000), 2)
    else:  # checking
        balance = round(random.uniform(0, 15000), 2)
    
    return {
        'account_id': '',  # Se asignará secuencialmente
        'customer_id': customer_id,
        'type': account_type,
        'balance': f"{balance:.2f}"
    }

def generate_combined_data(num_records: int) -> List[Dict[str, str]]:
    """
    Genera datos combinados de customer y account
    Cada cliente puede tener 1-3 cuentas
    """
    records = []
    customer_id = 1
    account_id = 1
    
    print(f"🏦 Generando {num_records} registros bancarios...")
    
    current_customer = None
    customer_accounts = 0
    max_accounts_per_customer = 0
    
    for i in range(num_records):
        # Decidir si crear nuevo cliente o nueva cuenta para cliente existente
        if current_customer is None or customer_accounts >= max_accounts_per_customer:
            # Crear nuevo cliente
            current_customer = generate_customer_data()
            current_customer['customer_id'] = customer_id
            customer_id += 1
            customer_accounts = 0
            max_accounts_per_customer = random.choices([1, 2, 3], weights=[50, 35, 15])[0]
        
        # Crear cuenta para el cliente actual
        account_data = generate_account_data(current_customer['customer_id'])
        account_data['account_id'] = account_id
        account_id += 1
        customer_accounts += 1
        
        # Combinar datos de customer y account en un solo registro
        combined_record = {
            # Datos del cliente
            'customer_id': current_customer['customer_id'],
            'customer_name': current_customer['name'],
            'customer_address': current_customer['address'],
            'customer_contact': current_customer['contact'],
            'customer_username': current_customer['username'],
            'customer_password': current_customer['password'],
            
            # Datos de la cuenta
            'account_id': account_data['account_id'],
            'account_type': account_data['type'],
            'account_balance': account_data['balance']
        }
        
        records.append(combined_record)
        
        # Mostrar progreso cada 100 registros
        if (i + 1) % 100 == 0:
            print(f"📊 Progreso: {i + 1}/{num_records} registros generados")
    
    return records

def save_to_csv(records: List[Dict[str, str]], filename: str = 'data.csv'):
    """
    Guarda los datos generados en un archivo CSV
    """
    if not records:
        print("❌ No hay datos para guardar")
        return
    
    print(f"💾 Guardando datos en {filename}...")
    
    # Definir el orden de las columnas
    fieldnames = [
        'customer_id', 'customer_name', 'customer_address', 
        'customer_contact', 'customer_username', 'customer_password',
        'account_id', 'account_type', 'account_balance'
    ]
    
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            # Escribir encabezados
            writer.writeheader()
            
            # Escribir datos
            writer.writerows(records)
        
        print(f"✅ Archivo {filename} creado exitosamente")
        print(f"📈 Total de registros: {len(records)}")
        
        # Mostrar estadísticas
        customers = len(set(record['customer_id'] for record in records))
        accounts = len(records)
        avg_accounts = accounts / customers if customers > 0 else 0
        
        print(f"👥 Clientes únicos: {customers}")
        print(f"🏦 Total de cuentas: {accounts}")
        print(f"📊 Promedio de cuentas por cliente: {avg_accounts:.1f}")
        
    except Exception as e:
        print(f"❌ Error al guardar el archivo: {e}")

def print_usage():
    """
    Muestra instrucciones de uso
    """
    print("🏦 CSV Generator - Sistema Bancario")
    print("=" * 40)
    print("Uso: python main.py <numero_de_lineas>")
    print()
    print("Ejemplos:")
    print("  python main.py 100     # Genera 100 registros")
    print("  python main.py 1000    # Genera 1000 registros")
    print("  python main.py 5000    # Genera 5000 registros")
    print()
    print("El archivo generado combina datos de:")
    print("  ✓ Tabla customer (cliente)")
    print("  ✓ Tabla account (cuenta bancaria)")

def main():
    """
    Función principal
    """
    print("🏦 Generador de CSV - Sistema Bancario")
    print("=" * 45)
    
    # Validar argumentos
    if len(sys.argv) != 2:
        print("❌ Número incorrecto de argumentos")
        print()
        print_usage()
        sys.exit(1)
    
    try:
        num_records = int(sys.argv[1])
        
        if num_records <= 0:
            print("❌ El número de registros debe ser mayor a 0")
            sys.exit(1)
        
        if num_records > 100000:
            confirm = input(f"⚠️  Vas a generar {num_records} registros. ¿Continuar? (y/N): ")
            if confirm.lower() != 'y':
                print("🚫 Operación cancelada")
                sys.exit(0)
    
    except ValueError:
        print("❌ El argumento debe ser un número entero")
        print()
        print_usage()
        sys.exit(1)
    
    # Generar datos
    try:
        print(f"🚀 Iniciando generación de {num_records} registros...")
        records = generate_combined_data(num_records)
        
        # Guardar en CSV
        save_to_csv(records)
        
        print("🎉 ¡Generación completada exitosamente!")
        
    except KeyboardInterrupt:
        print("\n🚫 Operación interrumpida por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error durante la generación: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()