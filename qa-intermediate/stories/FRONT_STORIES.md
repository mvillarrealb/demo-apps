# USER STORY - Sistema de Gestión Financiera Personal

## Descripción del Sistema

**Como usuario del sistema de gestión financiera personal**, quiero poder registrar, categorizar y analizar mis transacciones financieras para tener un control completo sobre mis ingresos y gastos, visualizar patrones de consumo y tomar decisiones financieras informadas.

## Stack Tecnológico
- **Frontend**: React 18 + TypeScript + TailwindCSS + React Router
- **Backend**: Spring Boot + JPA + REST API
- **Testing**: Vitest + React Testing Library
- **HTTP Client**: Axios

---

## 📋 CASOS DE PRUEBA QA

### **TC001: Navegación y Interfaz Principal**

#### **Objetivo**
Validar que la navegación principal funcione correctamente y que todas las páginas se carguen sin errores.

#### **Precondiciones**
- Sistema desplegado y accesible
- Backend API funcionando en `http://localhost:8080`
- Frontend funcionando en `http://localhost:5173`

#### **Pasos de Ejecución**
1. **Acceder a la página principal**
   - Navegar a `http://localhost:5173`
   - Verificar que se muestre la página de inicio (Home)

2. **Validar elementos de la página Home**
   - Verificar que aparezca el navbar con el logo "✨ FinanceApp"
   - Verificar que aparezcan los enlaces: "🏠 Inicio", "📊 Dashboard", "💳 Transacciones"
   - Verificar que aparezca el icono central con rayo y animación
   - Verificar que aparezca el título "Sistema de Finanzas Personales" con gradiente
   - Verificar que aparezcan las 4 tarjetas de características:
     - 📊 Dashboard Interactivo
     - 💰 Gestión de Transacciones  
     - 🔍 Filtros Avanzados
     - 📈 Análisis Financiero

3. **Probar navegación entre páginas**
   - Hacer clic en "📊 Dashboard" y verificar que redirija a `/dashboard`
   - Hacer clic en "💳 Transacciones" y verificar que redirija a `/transactions`
   - Hacer clic en "🏠 Inicio" y verificar que regrese a la página principal

4. **Validar efectos visuales**
   - Verificar efectos hover en el navbar (cambio de color, escalado)
   - Verificar que el icono central tenga animación `pulse`
   - Verificar que las tarjetas tengan efectos hover (sombra, escalado)

#### **Resultados Esperados**
- ✅ Todas las páginas cargan sin errores 404 o 500
- ✅ La navegación funciona correctamente entre rutas
- ✅ Todos los elementos visuales se muestran según el diseño
- ✅ Los efectos hover y animaciones funcionan suavemente
- ✅ El diseño es responsive en dispositivos móviles y desktop

#### **Criterios de Aceptación**
- Tiempo de carga de página < 3 segundos
- No hay errores de consola JavaScript
- El diseño se ve consistente en Chrome, Firefox y Safari
- La aplicación es usable en pantallas desde 320px hasta 1920px

---

### **TC002: Gestión de Transacciones - CRUD Completo**

#### **Objetivo**
Validar que el usuario pueda crear, visualizar, editar y eliminar transacciones financieras correctamente.

#### **Precondiciones**
- API Backend funcionando con al menos 2 categorías creadas
- Base de datos limpia o con datos de prueba conocidos
- Usuario en la página de Transacciones (`/transactions`)

#### **Pasos de Ejecución**

**Subtest 2A: Crear Nueva Transacción**
1. **Abrir modal de nueva transacción**
   - Hacer clic en el botón "Nuevo" o "Nueva Transacción"
   - Verificar que se abra el modal `NewTransactionModal`

2. **Llenar formulario con datos válidos**
   ```
   Account ID: "ACC-001"
   Posted At: "2024-01-15"
   Amount: 1500.50
   Type: "CREDIT"
   Currency: "PEN"
   Description: "Salario Enero 2024"
   Category: Seleccionar una categoría existente
   ```

3. **Guardar transacción**
   - Hacer clic en "Guardar" o "Crear"
   - Verificar que aparezca mensaje de éxito
   - Verificar que el modal se cierre
   - Verificar que la nueva transacción aparezca en la lista

**Subtest 2B: Validaciones de Formulario**
4. **Probar validaciones requeridas**
   - Intentar guardar con campos vacíos
   - Verificar mensajes de error para campos requeridos
   - Probar con monto negativo o cero
   - Probar con fecha futura inválida

**Subtest 2C: Editar Transacción Existente**
5. **Abrir edición de transacción**
   - Hacer clic en icono "✏️ Editar" de una transacción
   - Verificar que el modal se abra con datos pre-cargados

6. **Modificar datos**
   - Cambiar descripción a "Salario Enero 2024 - Actualizado"
   - Cambiar monto a 1600.00
   - Guardar cambios

7. **Verificar actualización**
   - Confirmar que los cambios se reflejen en la lista
   - Verificar que aparezca mensaje de actualización exitosa

**Subtest 2D: Eliminar Transacción**
8. **Eliminar transacción**
   - Hacer clic en icono "🗑️ Eliminar"
   - Verificar que aparezca modal de confirmación
   - Confirmar eliminación
   - Verificar que la transacción desaparezca de la lista

#### **Resultados Esperados**
- ✅ Modal de nueva transacción se abre/cierra correctamente
- ✅ Formulario valida todos los campos requeridos
- ✅ Transacciones se crean con datos correctos
- ✅ Edición actualiza datos sin crear duplicados
- ✅ Eliminación remueve la transacción permanentemente
- ✅ Mensajes de éxito/error aparecen apropiadamente

#### **Criterios de Aceptación**
- Las operaciones CRUD responden en < 2 segundos
- Los datos persisten correctamente en la base de datos
- No hay pérdida de datos durante las operaciones
- Los formularios manejan correctamente caracteres especiales

---

### **TC003: Filtros y Búsqueda de Transacciones**

#### **Objetivo**
Validar que el sistema de filtros permita buscar y filtrar transacciones por diferentes criterios de manera eficiente.

#### **Precondiciones**
- Base de datos con al menos 20 transacciones de prueba
- Transacciones con diferentes:
  - Tipos (CREDIT/DEBIT)
  - Categorías (mínimo 3 diferentes)
  - Fechas (últimos 6 meses)
  - Montos variados
- Usuario en página de Transacciones

#### **Pasos de Ejecución**

**Subtest 3A: Filtro por Texto**
1. **Buscar por descripción**
   - En el campo de búsqueda, escribir "Salario"
   - Verificar que solo aparezcan transacciones con "Salario" en la descripción
   - Probar búsqueda case-insensitive: "salario"

2. **Buscar por Account ID**
   - Buscar "ACC-001"
   - Verificar que solo aparezcan transacciones de esa cuenta

**Subtest 3B: Filtro por Categoría**
3. **Filtrar por categoría específica**
   - Seleccionar una categoría del dropdown
   - Verificar que solo aparezcan transacciones de esa categoría
   - Probar con "Todas las categorías"

**Subtest 3C: Filtro por Tipo de Transacción**
4. **Filtrar por CREDIT**
   - Seleccionar "Ingresos" o "CREDIT"
   - Verificar que solo aparezcan transacciones tipo CREDIT

5. **Filtrar por DEBIT**
   - Seleccionar "Gastos" o "DEBIT"
   - Verificar que solo aparezcan transacciones tipo DEBIT

**Subtest 3D: Filtro por Rango de Fechas**
6. **Filtrar por mes actual**
   - Seleccionar fechas del mes actual
   - Verificar que aparezcan solo transacciones del período

7. **Filtrar por rango personalizado**
   - Seleccionar "Desde: 2024-01-01" y "Hasta: 2024-01-31"
   - Verificar filtrado correcto

**Subtest 3E: Filtros Combinados**
8. **Aplicar múltiples filtros**
   - Buscar texto: "Supermercado"
   - Tipo: "DEBIT"
   - Categoría: "Alimentación"
   - Fecha: Último mes
   - Verificar que los resultados cumplan TODOS los criterios

**Subtest 3F: Limpieza de Filtros**
9. **Limpiar filtros**
   - Hacer clic en "Limpiar filtros" o similar
   - Verificar que se muestren todas las transacciones
   - Verificar que los campos de filtro se reseteen

#### **Resultados Esperados**
- ✅ La búsqueda por texto funciona en tiempo real (debounce)
- ✅ Filtros por categoría muestran resultados correctos
- ✅ Filtros por tipo (CREDIT/DEBIT) funcionan correctamente
- ✅ Filtros por fecha respetan los rangos seleccionados
- ✅ Filtros combinados funcionan con lógica AND
- ✅ Limpieza de filtros restaura vista completa

#### **Criterios de Aceptación**
- Búsqueda responde en < 500ms después del último keystroke
- Filtros mantienen estado durante navegación en la página
- No hay resultados falsos positivos/negativos
- Interfaz permanece responsive durante filtrado

---

### **TC004: Dashboard de Análisis Financiero**

#### **Objetivo**
Validar que el dashboard muestre correctamente las estadísticas financieras, gráficos y métricas de resumen.

#### **Precondiciones**
- Base de datos con transacciones de los últimos 3 meses
- Al menos 5 categorías diferentes asignadas
- Datos balanceados entre CREDIT y DEBIT
- Usuario en página Dashboard (`/dashboard`)

#### **Pasos de Ejecución**

**Subtest 4A: Métricas de Resumen**
1. **Validar estadísticas principales**
   - Verificar que aparezcan las tarjetas de métricas:
     - Total de Ingresos (suma de CREDIT)
     - Total de Gastos (suma de DEBIT)
     - Balance Neto (Ingresos - Gastos)
     - Número de Transacciones
   
2. **Verificar cálculos**
   - Anotar los valores mostrados
   - Calcular manualmente usando datos conocidos
   - Comparar que los valores coincidan

**Subtest 4B: Gráfico de Torta - Gastos por Categoría**
3. **Validar gráfico de distribución**
   - Verificar que aparezca gráfico de torta/dona
   - Verificar que muestre solo transacciones DEBIT
   - Verificar que cada categoría tenga color diferente
   - Verificar que aparezca leyenda con nombres de categorías

4. **Interactividad del gráfico**
   - Hover sobre segmentos del gráfico
   - Verificar que aparezca tooltip con valor y porcentaje
   - Verificar que los valores sumen el total de gastos

**Subtest 4C: Gráfico de Barras - Tendencias Mensuales**
5. **Validar gráfico de tendencias**
   - Verificar que aparezca gráfico de barras
   - Verificar barras para Ingresos y Gastos por mes
   - Verificar que aparezcan últimos 6 meses
   - Verificar leyenda y etiquetas de ejes

6. **Interactividad y tooltips**
   - Hover sobre barras
   - Verificar tooltips con valores exactos
   - Verificar que colores coincidan con leyenda

**Subtest 4D: Lista de Transacciones Recientes**
7. **Validar transacciones recientes**
   - Verificar que aparezcan últimas 5-10 transacciones
   - Verificar orden cronológico (más recientes primero)
   - Verificar que muestre: fecha, descripción, monto, categoría

8. **Enlaces de navegación**
   - Hacer clic en "Ver todas las transacciones"
   - Verificar que redirija a página de Transacciones

**Subtest 4E: Responsividad del Dashboard**
9. **Probar en diferentes tamaños**
   - Desktop (1920x1080)
   - Tablet (768x1024)
   - Móvil (375x667)
   - Verificar que gráficos se adapten correctamente

#### **Resultados Esperados**
- ✅ Todas las métricas calculan valores correctos
- ✅ Gráficos renderizan sin errores
- ✅ Gráfico de torta suma 100% de gastos
- ✅ Gráfico de barras muestra tendencias mensuales
- ✅ Transacciones recientes están ordenadas cronológicamente
- ✅ Dashboard es completamente responsive

#### **Criterios de Aceptación**
- Dashboard carga en < 3 segundos
- Cálculos son matemáticamente exactos
- Gráficos son legibles en todos los dispositivos
- No hay errores de rendering en los componentes de charts

---

## 🔧 **DATOS DE PRUEBA SUGERIDOS**

### **Categorías**
```json
[
  {"name": "Alimentación", "colorHex": "#10B981"},
  {"name": "Transporte", "colorHex": "#3B82F6"},
  {"name": "Entretenimiento", "colorHex": "#8B5CF6"},
  {"name": "Salud", "colorHex": "#F59E0B"},
  {"name": "Salario", "colorHex": "#059669"}
]
```

### **Transacciones de Ejemplo**
```json
[
  {
    "accountId": "ACC-001",
    "postedAt": "2024-01-15",
    "amount": 3500.00,
    "type": "CREDIT",
    "currency": "PEN",
    "description": "Salario Enero 2024",
    "categoryId": 5
  },
  {
    "accountId": "ACC-001",
    "postedAt": "2024-01-16",
    "amount": 150.50,
    "type": "DEBIT",
    "currency": "PEN",
    "description": "Supermercado Metro",
    "categoryId": 1
  },
  {
    "accountId": "ACC-001",
    "postedAt": "2024-01-17",
    "amount": 45.00,
    "type": "DEBIT",
    "currency": "PEN",
    "description": "Taxi al trabajo",
    "categoryId": 2
  }
]
```

---

## ⚠️ **CASOS EDGE Y VALIDACIONES ADICIONALES**

### **Validaciones de Seguridad**
- Inyección SQL en campos de búsqueda
- XSS en campos de descripción
- CSRF en formularios de transacciones

### **Validaciones de Performance**
- Comportamiento con > 1000 transacciones
- Tiempo de respuesta de filtros complejos
- Memoria utilizada en gráficos grandes

### **Validaciones de Usabilidad**
- Comportamiento sin JavaScript habilitado
- Accesibilidad con lectores de pantalla
- Navegación solo con teclado

---

## 📊 **MÉTRICAS DE CALIDAD**

### **Criterios de Aprobación Global**
- ✅ 100% de casos de prueba principales pasan
- ✅ 0 errores críticos o bloqueantes
- ✅ Tiempo de respuesta promedio < 2 segundos
- ✅ Compatibilidad con navegadores principales
- ✅ Diseño responsive en todos los dispositivos testados
- ✅ Sin errores de consola JavaScript