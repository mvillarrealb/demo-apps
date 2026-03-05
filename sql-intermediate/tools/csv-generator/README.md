# CSV Generator - Sistema Bancario

Generador de datos sintéticos en formato CSV para sistema bancario, combinando información de las tablas `customer` y `account`.

## Características

- ✅ **Datos realistas**: Usa Faker con localización en español
- ✅ **Modelo bancario**: Basado en el esquema PostgreSQL del proyecto
- ✅ **Relaciones coherentes**: Cada cliente puede tener 1-3 cuentas
- ✅ **Tipos de cuenta**: savings, checking, business, premium
- ✅ **Balances realistas**: Acordes al tipo de cuenta
- ✅ **Interfaz simple**: Un solo comando con argumentos

## Instalación

### 1. Crear Virtual Environment

```bash
# Navegar al directorio
cd tools/csv-generator

# Crear virtual environment
python3 -m venv venv

# Activar virtual environment
# En macOS/Linux:
source venv/bin/activate
# En Windows:
# venv\Scripts\activate
```

### 2. Instalar Dependencias

```bash
pip install -r requirements.txt
```

## Uso

### Sintaxis Básica

```bash
python main.py <numero_de_lineas>
```

### Ejemplos

```bash
# Generar 100 registros
python main.py 100

# Generar 1000 registros
python main.py 1000

# Generar 5000 registros
python main.py 5000
```

## Estructura del CSV Generado

El archivo `data.csv` generado contiene las siguientes columnas:

### Datos del Cliente (Tabla customer)
| Columna | Descripción | Ejemplo |
|---------|-------------|---------|
| `customer_id` | ID único del cliente | 1, 2, 3... |
| `customer_name` | Nombre completo | "Ana García López" |
| `customer_address` | Dirección completa | "Calle Mayor 123, Madrid" |
| `customer_contact` | Teléfono de contacto | "+34 666 123 456" |
| `customer_username` | Nombre de usuario único | "ana.garcia" |
| `customer_password` | Contraseña generada | "SecureP@ss123!" |

### Datos de la Cuenta (Tabla account)
| Columna | Descripción | Ejemplo |
|---------|-------------|---------|
| `account_id` | ID único de la cuenta | 1, 2, 3... |
| `account_type` | Tipo de cuenta bancaria | "savings", "checking", "business", "premium" |
| `account_balance` | Saldo de la cuenta | "1250.75" |

## Lógica de Generación

### Distribución de Cuentas por Cliente
- **50%** de clientes: 1 cuenta
- **35%** de clientes: 2 cuentas  
- **15%** de clientes: 3 cuentas

### Rangos de Balance por Tipo de Cuenta
- **savings**: $100 - $50,000
- **checking**: $0 - $15,000
- **business**: $5,000 - $100,000
- **premium**: $10,000 - $250,000

### Localización de Datos
- **Nombres**: Españoles y latinoamericanos
- **Direcciones**: Formato español/mexicano
- **Teléfonos**: Formatos internacionales
- **Usernames**: Basados en nombres reales

## Ejemplo de Salida

```csv
customer_id,customer_name,customer_address,customer_contact,customer_username,customer_password,account_id,account_type,account_balance
1,"María Rodriguez","Av. Libertad 456, Barcelona","+34 612 345 678","maria.rodriguez","MyP@ssw0rd!",1,"savings","15750.25"
1,"María Rodriguez","Av. Libertad 456, Barcelona","+34 612 345 678","maria.rodriguez","MyP@ssw0rd!",2,"checking","2100.50"
2,"Carlos Mendez","Calle Sol 789, Sevilla","+34 655 987 321","carlos.mendez","Secure123$",3,"business","45000.00"
```

## Validaciones

### Argumentos
- ✅ Debe especificarse exactamente un argumento
- ✅ El argumento debe ser un número entero positivo
- ✅ Para más de 100,000 registros se solicita confirmación

### Datos Generados
- ✅ IDs únicos y secuenciales
- ✅ Usernames únicos por cliente
- ✅ Balances coherentes con tipo de cuenta
- ✅ Relaciones FK válidas (customer_id en accounts)

## Estadísticas de Salida

Al finalizar, el script muestra:
- 📈 Total de registros generados
- 👥 Número de clientes únicos
- 🏦 Total de cuentas bancarias
- 📊 Promedio de cuentas por cliente

## Casos de Uso

### Testing y Desarrollo
```bash
# Datos mínimos para pruebas
python main.py 50
```

### Demos y Presentaciones
```bash
# Cantidad media para demostraciones
python main.py 500
```

### Pruebas de Performance
```bash
# Grandes volúmenes para testing
python main.py 10000
```

## Integración con Otros Tools

Este CSV puede importarse directamente en:

### Base de Datos
```sql
-- PostgreSQL
COPY customer_accounts FROM '/path/data.csv' DELIMITER ',' CSV HEADER;
```

### Excel/Sheets
- Abrir directamente el archivo CSV
- Importar con delimitador de coma
- Configurar encoding UTF-8

### Herramientas de Análisis
- Pandas: `pd.read_csv('data.csv')`
- R: `read.csv('data.csv')`
- Power BI/Tableau: Importación directa

## Personalización

Para modificar la generación de datos, edita las siguientes funciones en `main.py`:

### Cambiar Tipos de Cuenta
```python
account_types = ['savings', 'checking', 'business', 'premium', 'student']
```

### Ajustar Rangos de Balance
```python
if account_type == 'student':
    balance = round(random.uniform(0, 1000), 2)
```

### Modificar Localización
```python
fake = Faker(['en_US'])  # Para datos en inglés
```

## Troubleshooting

### Error: "faker not found"
```bash
# Asegúrate de activar el virtual environment
source venv/bin/activate
pip install -r requirements.txt
```

### Error: "Permission denied"
```bash
# En Unix/Linux, hacer ejecutable
chmod +x main.py
```

### Archivo muy grande
```bash
# Para archivos grandes, considera usar compresión
python main.py 100000
gzip data.csv
```

## Contribución

Para agregar nuevas funcionalidades:

1. **Nuevos campos**: Agregar a `generate_customer_data()` o `generate_account_data()`
2. **Nuevas validaciones**: Modificar la función `main()`
3. **Nuevos formatos**: Crear funciones de exportación adicionales

## Compatibilidad

- **Python**: 3.8+
- **SO**: Windows, macOS, Linux
- **Memoria**: ~100MB para 100k registros
- **Disco**: ~10MB por 100k registros

---

**¡Genera datos bancarios realistas en segundos! 🏦**