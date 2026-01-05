#!/bin/bash

# Script de pruebas para generar datos realistas del Sistema de Finanzas Personales
# Autor: Sistema Generado
# Fecha: 2025-09-15

# Configuración
BASE_URL="http://localhost:8080/api"
CONTENT_TYPE="Content-Type: application/json"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Función para hacer peticiones POST
post_request() {
    local endpoint="$1"
    local data="$2"
    local description="$3"
    
    log "Creando: $description"
    response=$(curl -s -X POST "$BASE_URL$endpoint" \
        -H "$CONTENT_TYPE" \
        -d "$data" \
        -w "%{http_code}")
    
    http_code="${response: -3}"
    response_body="${response%???}"
    
    if [[ "$http_code" -eq 201 ]]; then
        success "$description creado exitosamente"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        return 0
    else
        error "Falló la creación de $description (HTTP: $http_code)"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        return 1
    fi
}

# Función para hacer peticiones GET
get_request() {
    local endpoint="$1"
    local description="$2"
    
    log "Consultando: $description"
    response=$(curl -s -X GET "$BASE_URL$endpoint" -w "%{http_code}")
    
    http_code="${response: -3}"
    response_body="${response%???}"
    
    if [[ "$http_code" -eq 200 ]]; then
        success "$description obtenido exitosamente"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        return 0
    else
        error "Falló la consulta de $description (HTTP: $http_code)"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        return 1
    fi
}

# Verificar que jq está instalado
if ! command -v jq &> /dev/null; then
    warning "jq no está instalado. Los JSON no se formatearán."
fi

# Verificar que el servidor está corriendo
log "Verificando conectividad con el servidor..."
if ! curl -s "$BASE_URL/categories" > /dev/null; then
    error "No se puede conectar al servidor en $BASE_URL"
    error "Asegúrate de que el servidor Spring Boot esté corriendo en el puerto 8080"
    exit 1
fi

success "Servidor disponible en $BASE_URL"

echo ""
echo "=========================================="
echo "   GENERACIÓN DE DATOS DE PRUEBA"
echo "=========================================="
echo ""

# ============================================
# PASO 1: CREAR CATEGORÍAS
# ============================================

log "PASO 1: Creando categorías de transacciones..."
echo ""

# Arrays separados para nombres y colores (más compatible con bash)
category_names=("Restaurantes" "Pago de Servicios" "Pago de Tarjetas" "Entretenimiento" "Supermercados" "Transferencias")
category_colors=("#FF5722" "#2196F3" "#9C27B0" "#E91E63" "#4CAF50" "#FF9800")

category_ids=()

# Crear categorías iterando por índices
for i in "${!category_names[@]}"; do
    category_name="${category_names[$i]}"
    color_hex="${category_colors[$i]}"
    
    category_data='{
        "name": "'"$category_name"'",
        "colorHex": "'"$color_hex"'"
    }'
    
    if post_request "/categories" "$category_data" "Categoría: $category_name"; then
        echo ""
    fi
done

echo ""
log "Esperando 2 segundos para que se procesen las categorías..."
sleep 2

# ============================================
# PASO 2: CREAR TRANSACCIONES
# ============================================

log "PASO 2: Creando transacciones realistas..."
log "NOTA: Todos los montos se almacenan como valores positivos en la BD."
log "      El tipo (DEBIT/CREDIT) determina si es gasto o ingreso."
log "      En las agregaciones, los DEBIT aparecen como negativos."
echo ""

# Array de cuentas
accounts=("ACC001" "ACC002" "ACC003" "ACC004")

# Función para generar fecha aleatoria en los últimos 3 meses
generate_random_date() {
    local days_ago=$((RANDOM % 90 + 1))  # Entre 1 y 90 días atrás
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -v-${days_ago}d -u +"%Y-%m-%dT%H:%M:%S.000Z"
    else
        # Linux
        date -d "$days_ago days ago" -u +"%Y-%m-%dT%H:%M:%S.000Z"
    fi
}

# Función para generar hora aleatoria
generate_random_time() {
    local hour=$((RANDOM % 24))
    local minute=$((RANDOM % 60))
    printf "%02d:%02d:00.000Z" $hour $minute
}

# Función para asegurar que el monto sea positivo
ensure_positive_amount() {
    local amount=$1
    # Remover cualquier signo negativo y asegurar que sea un número positivo
    amount=$(echo "$amount" | tr -d '-' | tr -d '+')
    # Si el monto es 0 o menor, establecer un mínimo de 1
    if [[ $amount -le 0 ]]; then
        amount=1
    fi
    echo "$amount"
}

# Transacciones para cada cuenta
create_transactions_for_account() {
    local account_id="$1"
    log "Creando transacciones para cuenta: $account_id"
    
    # Restaurantes (gastos frecuentes)
    for i in {1..8}; do
        local amount=$((RANDOM % 80 + 20))  # Entre 20 y 100 soles (siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        local restaurants=("McDonald's" "KFC" "Pizza Hut" "Chili's" "Pardos Chicken" "La Rosa Náutica" "Astrid y Gastón" "Maido")
        local restaurant=${restaurants[$((RANDOM % ${#restaurants[@]}))]}
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "DEBIT",
            "currency": "PEN",
            "description": "Consumo en '"$restaurant"'",
            "categoryId": 1
        }'
        
        post_request "/transactions" "$transaction_data" "Gasto en $restaurant - $account_id" > /dev/null
    done
    
    # Pago de Servicios (gastos mensuales)
    for i in {1..4}; do
        local services=("Luz - Enel" "Agua - Sedapal" "Gas - Cálidda" "Internet - Movistar" "Cable - DirecTV" "Teléfono - Claro")
        local service=${services[$((RANDOM % ${#services[@]}))]}
        local amount=$((RANDOM % 200 + 50))  # Entre 50 y 250 soles (siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "DEBIT",
            "currency": "PEN",
            "description": "Pago de '"$service"'",
            "categoryId": 2
        }'
        
        post_request "/transactions" "$transaction_data" "Pago de $service - $account_id" > /dev/null
    done
    
    # Pago de Tarjetas (gastos grandes mensuales)
    for i in {1..3}; do
        local cards=("Visa BCP" "Mastercard BBVA" "American Express Interbank" "Visa Scotiabank")
        local card=${cards[$((RANDOM % ${#cards[@]}))]}
        local amount=$((RANDOM % 1500 + 500))  # Entre 500 y 2000 soles (siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "DEBIT",
            "currency": "PEN",
            "description": "Pago de tarjeta '"$card"'",
            "categoryId": 3
        }'
        
        post_request "/transactions" "$transaction_data" "Pago de $card - $account_id" > /dev/null
    done
    
    # Entretenimiento (gastos variables)
    for i in {1..6}; do
        local entertainment=("Netflix" "Spotify" "Cineplanet" "Jockey Plaza" "Real Plaza" "Parque de las Aguas" "Circuito Mágico del Agua" "Teatro Municipal")
        local place=${entertainment[$((RANDOM % ${#entertainment[@]}))]}
        local amount=$((RANDOM % 150 + 25))  # Entre 25 y 175 soles (siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "DEBIT",
            "currency": "PEN",
            "description": "Entretenimiento en '"$place"'",
            "categoryId": 4
        }'
        
        post_request "/transactions" "$transaction_data" "Entretenimiento $place - $account_id" > /dev/null
    done
    
    # Supermercados (gastos frecuentes)
    for i in {1..10}; do
        local supermarkets=("Metro" "Plaza Vea" "Tottus" "Wong" "Vivanda" "Makro")
        local supermarket=${supermarkets[$((RANDOM % ${#supermarkets[@]}))]}
        local amount=$((RANDOM % 300 + 80))  # Entre 80 y 380 soles (siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "DEBIT",
            "currency": "PEN",
            "description": "Compras en '"$supermarket"'",
            "categoryId": 5
        }'
        
        post_request "/transactions" "$transaction_data" "Compras $supermarket - $account_id" > /dev/null
    done
    
    # Transferencias (ingresos y egresos)
    for i in {1..5}; do
        local transfer_types=("Salario mensual" "Freelance trabajo" "Venta de producto" "Transferencia recibida" "Depósito familiar")
        local transfer=${transfer_types[$((RANDOM % ${#transfer_types[@]}))]}
        local amount=$((RANDOM % 2000 + 1000))  # Entre 1000 y 3000 soles (ingresos - siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "CREDIT",
            "currency": "PEN",
            "description": "'"$transfer"'",
            "categoryId": 6
        }'
        
        post_request "/transactions" "$transfer - $account_id" > /dev/null
    done
    
    # Transferencias enviadas (egresos)
    for i in {1..3}; do
        local sent_transfers=("Transferencia a familiar" "Pago a proveedor" "Envío de dinero" "Pago de deuda")
        local transfer=${sent_transfers[$((RANDOM % ${#sent_transfers[@]}))]}
        local amount=$((RANDOM % 800 + 200))  # Entre 200 y 1000 soles (siempre positivo)
        # Asegurar que el monto sea positivo
        amount=$(ensure_positive_amount "$amount")
        local date=$(generate_random_date)
        
        transaction_data='{
            "accountId": "'"$account_id"'",
            "postedAt": "'"$date"'",
            "amount": '"$amount"',
            "type": "DEBIT",
            "currency": "PEN",
            "description": "'"$transfer"'",
            "categoryId": 6
        }'
        
        post_request "/transactions" "$transfer - $account_id" > /dev/null
    done
    
    success "Transacciones creadas para cuenta: $account_id"
    echo ""
}

# Crear transacciones para cada cuenta
for account in "${accounts[@]}"; do
    create_transactions_for_account "$account"
done

echo ""
log "Esperando 3 segundos para que se procesen todas las transacciones..."
sleep 3

# ============================================
# PASO 3: REALIZAR CONSULTAS DE PRUEBA
# ============================================

log "PASO 3: Realizando consultas de prueba comprensivas..."
echo ""

# Consultar todas las categorías
echo "=========================================="
echo "           CATEGORÍAS CREADAS"
echo "=========================================="
get_request "/categories" "Todas las categorías"
echo ""

# Consultar transacciones por páginas
echo "=========================================="
echo "        TRANSACCIONES (Primera página)"
echo "=========================================="
get_request "/transactions?page=0&size=10&sort=postedAt,DESC" "Primeras 10 transacciones (más recientes)"
echo ""

# Consultar transacciones por cada cuenta
for account in "${accounts[@]}"; do
    echo "=========================================="
    echo "      AGREGACIONES POR CUENTA: $account"
    echo "=========================================="
    
    # Últimos 30 días
    from_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d "30 days ago" +%Y-%m-%d)
    to_date=$(date +%Y-%m-%d)
    
    get_request "/transactions/groupedBy?series=category&accountId=$account&fromDate=$from_date&toDate=$to_date" "Agregaciones de $account (últimos 30 días)"
    echo ""
done

# Consultar agregaciones generales
echo "=========================================="
echo "        AGREGACIONES GENERALES"
echo "=========================================="
from_date=$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d "60 days ago" +%Y-%m-%d)
to_date=$(date +%Y-%m-%d)

get_request "/transactions/groupedBy?series=category&fromDate=$from_date&toDate=$to_date" "Agregaciones generales (últimos 60 días)"
echo ""

# Consultas específicas por categoría
echo "=========================================="
echo "      TRANSACCIONES POR CATEGORÍA"
echo "=========================================="
get_request "/transactions?categoryId=1&page=0&size=5" "Transacciones de Restaurantes (primeras 5)"
echo ""

get_request "/transactions?categoryId=5&page=0&size=5" "Transacciones de Supermercados (primeras 5)"
echo ""

# Búsqueda por texto
echo "=========================================="
echo "         BÚSQUEDAS POR TEXTO"
echo "=========================================="
get_request "/transactions?q=Netflix&page=0&size=5" "Búsqueda: Netflix"
echo ""

get_request "/transactions?q=Metro&page=0&size=5" "Búsqueda: Metro"
echo ""

# Filtros por monto
echo "=========================================="
echo "        FILTROS POR MONTO"
echo "=========================================="
get_request "/transactions?minAmount=500&maxAmount=1000&page=0&size=10" "Transacciones entre 500 y 1000 soles"
echo ""

# Filtros por tipo
echo "=========================================="
echo "         FILTROS POR TIPO"
echo "=========================================="
get_request "/transactions?type=CREDIT&page=0&size=10" "Solo ingresos (CREDIT)"
echo ""

get_request "/transactions?type=DEBIT&page=0&size=10" "Solo gastos (DEBIT)"
echo ""

echo ""
echo "=========================================="
echo "           RESUMEN FINAL"
echo "=========================================="
echo ""

success "Script de generación de datos completado exitosamente"
log "Se han creado:"
log "  - 6 categorías principales"
log "  - Aproximadamente 140+ transacciones distribuidas en 4 cuentas"
log "  - Datos realistas con fechas de los últimos 90 días"
log "  - Mezcla de ingresos y gastos por categoría"
echo ""

warning "Para consultas adicionales, puedes usar:"
echo "  - GET $BASE_URL/categories - Ver todas las categorías"
echo "  - GET $BASE_URL/transactions - Ver todas las transacciones (paginado)"
echo "  - GET $BASE_URL/transactions/groupedBy?series=category - Agregaciones generales"
echo "  - GET $BASE_URL/transactions/groupedBy?series=category&accountId=ACC001 - Por cuenta específica"
echo ""

log "¡Datos de prueba listos para uso!"