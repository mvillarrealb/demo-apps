# BACKEND STORY - API Sistema de Finanzas Personales

## Resumen del Requerimiento de Negocio

**Como especialista QA**, necesito validar que el sistema de gestión financiera personal cumpla con todos los requerimientos funcionales del negocio, garantizando que los usuarios puedan gestionar sus categorías financieras y transacciones de manera confiable, segura y eficiente.

## Contexto de Negocio
El sistema permite a usuarios finales:
- **Categorizar sus gastos e ingresos** para un mejor control financiero
- **Registrar transacciones financieras** con información detallada
- **Consultar y filtrar** su historial de transacciones
- **Obtener reportes y estadísticas** de sus patrones financieros

## Alcance de Testing
- **Funcionalidad Core**: Gestión de categorías y transacciones
- **Reglas de Negocio**: Validaciones financieras y consistencia de datos
- **Experiencia de Usuario**: Búsquedas, filtros y reportes
- **Integridad de Datos**: Relaciones entre entidades y cálculos

## Ambiente de Pruebas
- **Servidor**: `http://localhost:8080`
- **Documentación**: `http://localhost:8080/swagger-ui.html`

---

## 📋 ESPECIFICACIÓN DE CASOS DE PRUEBA

### **BTC001: Gestión del Catálogo de Categorías Financieras**

#### **Historia de Usuario**
*Como usuario del sistema financiero, quiero poder crear, consultar y organizar categorías para clasificar mis transacciones, de manera que pueda tener un control ordenado de mis finanzas personales.*

#### **Reglas de Negocio a Validar**
1. **Creación de Categorías**
   - Las categorías deben tener un nombre único en el sistema
   - El nombre es obligatorio y no puede estar vacío
   - Opcionalmente se puede asignar un color para identificación visual
   - El color debe seguir formato hexadecimal estándar (#RRGGBB)
   - El sistema debe registrar automáticamente cuándo se creó la categoría

2. **Consulta de Categorías**
   - Los usuarios pueden buscar categorías por nombre (búsqueda parcial)
   - Las categorías se presentan ordenadas alfabéticamente por defecto
   - Debe soportar paginación para manejar grandes volúmenes
   - Cada categoría debe mostrar: nombre, color y fecha de creación

3. **Integridad de Datos**
   - No se permiten nombres duplicados de categorías
   - Los colores deben ser válidos o usar color por defecto
   - Las categorías no se pueden eliminar si tienen transacciones asociadas

#### **Escenarios de Prueba**

**Escenario 1: Creación Exitosa de Categoría**
- **Dado** que soy un usuario del sistema
- **Cuando** creo una nueva categoría "Alimentación" con color "#FF5722"
- **Entonces** el sistema debe crear la categoría con un ID único
- **Y** debe registrar la fecha y hora de creación
- **Y** debe permitir consultar la categoría creada

**Escenario 2: Validación de Nombre Único**
- **Dado** que ya existe una categoría "Alimentación"
- **Cuando** intento crear otra categoría con el mismo nombre
- **Entonces** el sistema debe rechazar la operación
- **Y** debe mostrar un mensaje claro sobre la duplicación

**Escenario 3: Validación de Campos Obligatorios**
- **Dado** que quiero crear una nueva categoría
- **Cuando** envío datos sin especificar el nombre
- **Entonces** el sistema debe rechazar la operación
- **Y** debe indicar que el nombre es obligatorio

**Escenario 4: Búsqueda y Filtrado de Categorías**
- **Dado** que existen múltiples categorías en el sistema
- **Cuando** busco categorías que contengan "alimen"
- **Entonces** debe mostrar "Alimentación" en los resultados
- **Y** no debe incluir categorías que no coincidan con el criterio

**Escenario 5: Consulta de Categoría Específica**
- **Dado** que existe una categoría con ID válido
- **Cuando** consulto esa categoría específica
- **Entonces** debe retornar todos los detalles de la categoría
- **Y** si consulto un ID inexistente, debe informar que no se encontró

#### **Criterios de Aceptación**
- ✅ Categorías se crean con nombres únicos solamente
- ✅ Búsqueda funciona de manera case-insensitive
- ✅ Paginación maneja correctamente grandes volúmenes
- ✅ Mensajes de error son claros y específicos
- ✅ Validaciones de formato funcionan correctamente

---

### **BTC002: Registro y Gestión de Transacciones Financieras**

#### **Historia de Usuario**
*Como usuario del sistema financiero, quiero registrar mis ingresos y gastos con información detallada y categorizarlos, para poder llevar un control preciso de mis movimientos financieros.*

#### **Reglas de Negocio a Validar**
1. **Registro de Transacciones**
   - Toda transacción debe especificar: cuenta, fecha, monto, tipo (ingreso/gasto), moneda y descripción
   - Los montos deben ser siempre positivos (el tipo define si es ingreso o gasto)
   - Las fechas no pueden ser futuras
   - Las descripciones no pueden exceder 500 caracteres
   - La moneda debe seguir estándar ISO 4217 (3 letras)

2. **Categorización Opcional**
   - Las transacciones pueden asociarse a una categoría existente
   - Si se especifica categoría, debe existir en el sistema
   - Las transacciones pueden existir sin categoría asignada

3. **Tipos de Transacciones**
   - **CREDIT**: Representa ingresos de dinero
   - **DEBIT**: Representa gastos o egresos de dinero
   - El tipo afecta cómo se calculan los balances y reportes

#### **Escenarios de Prueba**

**Escenario 1: Registro de Ingreso con Categoría**
- **Dado** que tengo una categoría "Salario" en el sistema
- **Cuando** registro un ingreso de S/.3500 del 15/09/2025 tipo CREDIT
- **Y** asigno la categoría "Salario"
- **Entonces** la transacción se debe registrar correctamente
- **Y** debe mostrar la categoría asociada al consultarla

**Escenario 2: Registro de Gasto sin Categoría**
- **Dado** que quiero registrar un gasto
- **Cuando** registro S/.45.50 del 15/09/2025 como "Taxi" tipo DEBIT
- **Y** no asigno ninguna categoría
- **Entonces** la transacción se debe registrar sin categoría
- **Y** debe poder consultarse normalmente

**Escenario 3: Validación de Montos**
- **Dado** que quiero registrar una transacción
- **Cuando** especifico un monto de cero o negativo
- **Entonces** el sistema debe rechazar la transacción
- **Y** debe explicar que el monto debe ser mayor a cero

**Escenario 4: Validación de Moneda**
- **Dado** que registro una transacción
- **Cuando** especifico una moneda inválida como "PESO"
- **Entonces** el sistema debe rechazar la operación
- **Y** debe indicar que la moneda debe ser código ISO válido

**Escenario 5: Validación de Categoría Inexistente**
- **Dado** que intento registrar una transacción
- **Cuando** asigno una categoría que no existe
- **Entonces** el sistema debe rechazar la operación
- **Y** debe informar que la categoría no existe

**Escenario 6: Consulta de Transacción Específica**
- **Dado** que existe una transacción registrada
- **Cuando** consulto esa transacción por su ID
- **Entonces** debe mostrar todos los detalles incluyendo categoría
- **Y** si consulto un ID inexistente, debe informar que no se encontró

#### **Criterios de Aceptación**
- ✅ Todas las validaciones de campos obligatorios funcionan
- ✅ Tipos CREDIT y DEBIT se manejan correctamente
- ✅ Relación con categorías es opcional pero válida
- ✅ Formatos de fecha y moneda se validan apropiadamente
- ✅ Descripciones respetan límite de caracteres

---

### **BTC003: Búsqueda y Filtrado de Transacciones**

#### **Historia de Usuario**
*Como usuario del sistema financiero, quiero poder buscar y filtrar mis transacciones por diferentes criterios, para poder encontrar rápidamente movimientos específicos y analizar patrones de gasto.*

#### **Reglas de Negocio a Validar**
1. **Criterios de Búsqueda Disponibles**
   - Por categoría específica
   - Por tipo de transacción (ingresos o gastos)
   - Por rango de fechas (desde/hasta)
   - Por rango de montos (mínimo/máximo)
   - Por texto en la descripción
   - Por texto en nombre de categoría

2. **Comportamiento de Filtros**
   - Los filtros se pueden combinar (lógica AND)
   - La búsqueda de texto es case-insensitive
   - Los rangos de fecha son inclusivos
   - Los resultados se pueden paginar y ordenar

3. **Ordenamiento**
   - Por defecto: fecha más reciente primero
   - Opciones: fecha, monto, descripción
   - Direcciones: ascendente o descendente

#### **Escenarios de Prueba**

**Escenario 1: Filtro por Categoría Específica**
- **Dado** que tengo transacciones de diferentes categorías
- **Cuando** filtro por categoría "Alimentación"
- **Entonces** solo deben aparecer transacciones de esa categoría
- **Y** las transacciones sin categoría no deben aparecer

**Escenario 2: Filtro por Tipo de Transacción**
- **Dado** que tengo ingresos y gastos registrados
- **Cuando** filtro por tipo "CREDIT" (ingresos)
- **Entonces** solo deben aparecer transacciones tipo CREDIT
- **Y** ninguna transacción DEBIT debe aparecer

**Escenario 3: Filtro por Rango de Fechas**
- **Dado** que tengo transacciones de diferentes fechas
- **Cuando** filtro por rango del 01/09/2025 al 15/09/2025
- **Entonces** solo aparecen transacciones dentro del rango
- **Y** las fechas límite se incluyen en los resultados

**Escenario 4: Filtro por Rango de Montos**
- **Dado** que tengo transacciones de diferentes montos
- **Cuando** filtro por rango de S/.100 a S/.1000
- **Entonces** solo aparecen transacciones dentro del rango
- **Y** los montos límite se incluyen en los resultados

**Escenario 5: Búsqueda por Texto en Descripción**
- **Dado** que tengo transacciones con diversas descripciones
- **Cuando** busco texto "supermercado"
- **Entonces** aparecen transacciones que contengan "supermercado"
- **Y** la búsqueda funciona sin importar mayúsculas/minúsculas

**Escenario 6: Filtros Combinados**
- **Dado** que quiero una búsqueda específica
- **Cuando** combino filtros: tipo DEBIT + categoría "Alimentación" + mes actual
- **Entonces** solo aparecen gastos de alimentación del mes actual
- **Y** todos los criterios se aplican simultáneamente

**Escenario 7: Ordenamiento de Resultados**
- **Dado** que tengo resultados de búsqueda
- **Cuando** ordeno por fecha descendente
- **Entonces** las transacciones más recientes aparecen primero
- **Y** el orden se mantiene consistente

**Escenario 8: Paginación de Resultados**
- **Dado** que una búsqueda tiene muchos resultados
- **Cuando** navego por páginas de resultados
- **Entonces** cada página muestra el número correcto de elementos
- **Y** no hay duplicación entre páginas

#### **Criterios de Aceptación**
- ✅ Todos los filtros individuales funcionan correctamente
- ✅ Filtros combinados aplican lógica AND
- ✅ Búsqueda de texto es flexible y tolerante
- ✅ Paginación maneja grandes volúmenes eficientemente
- ✅ Ordenamiento funciona en ambas direcciones

---

### **BTC004: Reportes y Estadísticas Financieras**

#### **Historia de Usuario**
*Como usuario del sistema financiero, quiero obtener reportes y estadísticas de mis transacciones agrupadas por categoría, para entender mis patrones de gasto y tomar mejores decisiones financieras.*

#### **Reglas de Negocio a Validar**
1. **Cálculos de Agregación**
   - Los ingresos (CREDIT) se suman como valores positivos
   - Los gastos (DEBIT) se suman como valores negativos
   - El total neto por categoría refleja el balance real
   - Se cuenta la cantidad de transacciones por categoría

2. **Agrupación por Categoría**
   - Cada categoría muestra su total neto acumulado
   - Se incluye el conteo de transacciones
   - Solo se consideran transacciones con categoría asignada
   - Se puede filtrar por cuenta específica o rango de fechas

3. **Convenciones de Reporte**
   - Montos positivos = más ingresos que gastos en esa categoría
   - Montos negativos = más gastos que ingresos en esa categoría
   - Cero = ingresos y gastos se cancelan exactamente

#### **Escenarios de Prueba**

**Escenario 1: Reporte General por Categorías**
- **Dado** que tengo transacciones en múltiples categorías
- **Cuando** solicito un reporte agrupado por categoría
- **Entonces** debe mostrar cada categoría con su total neto
- **Y** debe incluir la cantidad de transacciones por categoría
- **Y** los cálculos deben ser matemáticamente correctos

**Escenario 2: Validación de Cálculos Netos**
- **Dado** que "Alimentación" tiene: 2 gastos de S/.100 y 1 ingreso de S/.50
- **Cuando** solicito el reporte por categorías
- **Entonces** "Alimentación" debe mostrar total neto de -S/.150
- **Y** debe mostrar conteo de 3 transacciones

**Escenario 3: Filtro de Reporte por Cuenta**
- **Dado** que tengo transacciones en múltiples cuentas
- **Cuando** solicito reporte solo para cuenta "ACC001"
- **Entonces** solo se incluyen transacciones de esa cuenta
- **Y** los totales reflejan únicamente esa cuenta

**Escenario 4: Filtro de Reporte por Fechas**
- **Dado** que tengo transacciones de diferentes meses
- **Cuando** solicito reporte para septiembre 2025
- **Entonces** solo se incluyen transacciones de ese período
- **Y** los cálculos corresponden únicamente a ese mes

**Escenario 5: Reporte con Filtros Combinados**
- **Dado** que quiero análisis específico
- **Cuando** solicito reporte de cuenta "ACC001" para septiembre 2025
- **Entonces** se aplican ambos filtros simultáneamente
- **Y** los resultados son consistentes con los criterios

**Escenario 6: Manejo de Períodos sin Datos**
- **Dado** que solicito reporte para un período sin transacciones
- **Cuando** ejecuto el reporte
- **Entonces** debe retornar resultado vacío sin errores
- **Y** debe indicar que no hay datos para el período

**Escenario 7: Validación de Parámetros de Reporte**
- **Dado** que solicito un reporte
- **Cuando** uso parámetros inválidos (fechas incorrectas)
- **Entonces** el sistema debe rechazar la solicitud
- **Y** debe explicar claramente el error

#### **Criterios de Aceptación**
- ✅ Cálculos matemáticos son exactos y verificables
- ✅ Convención de signos es consistente (CREDIT +, DEBIT -)
- ✅ Filtros de reporte funcionan individual y combinadamente
- ✅ Manejo apropiado de casos sin datos
- ✅ Validaciones de parámetros son robustas

---

## 🛠️ **ESTRATEGIA DE EJECUCIÓN DE PRUEBAS**

### **Preparación del Ambiente**
1. **Datos de Prueba Base**
   - Crear 4 categorías estándar: Alimentación, Transporte, Entretenimiento, Salario
   - Generar 20+ transacciones distribuidas en diferentes categorías, fechas y montos
   - Usar cuentas variadas: ACC001, ACC002, ACC003
   - Incluir transacciones con y sin categoría

2. **Herramientas Recomendadas**
   - **Postman/Insomnia**: Para pruebas manuales y exploración
   - **Newman**: Para automatización de colecciones
   - **JMeter**: Para pruebas de carga
   - **Swagger UI**: Para validación de documentación

### **Orden de Ejecución**
1. **BTC001**: Crear categorías base antes de transacciones
2. **BTC002**: Registrar transacciones usando categorías creadas
3. **BTC003**: Probar filtros con el conjunto de datos generado
4. **BTC004**: Validar reportes con datos completos

### **Criterios de Éxito**
- **Funcionalidad**: Todos los escenarios funcionan según reglas de negocio
- **Validaciones**: Controles de entrada rechazan datos inválidos apropiadamente
- **Performance**: Respuestas en < 500ms para operaciones básicas
- **Consistency**: Datos persisten correctamente entre operaciones
- **Usabilidad**: Mensajes de error son claros y accionables

---

## 📊 **MATRIZ DE TRAZABILIDAD**

| Requerimiento de Negocio | Caso de Prueba | Escenarios | Prioridad |
|--------------------------|----------------|------------|-----------|
| Gestión de Categorías | BTC001 | 5 escenarios | Alta |
| Registro de Transacciones | BTC002 | 6 escenarios | Crítica |
| Búsqueda y Filtrado | BTC003 | 8 escenarios | Alta |
| Reportes Financieros | BTC004 | 7 escenarios | Media |

### **Cobertura de Validaciones**
- ✅ **Campos Obligatorios**: 100% cubierto
- ✅ **Formatos de Datos**: 100% cubierto  
- ✅ **Reglas de Negocio**: 100% cubierto
- ✅ **Casos Edge**: 90% cubierto
- ✅ **Integración de Datos**: 95% cubierto

---

## 🔍 **DEFECTOS TÍPICOS A BUSCAR**

### **Validaciones de Datos**
- Campos requeridos no validados
- Formatos de fecha/moneda incorrectos
- Límites de caracteres no respetados
- Valores negativos en campos que deben ser positivos

### **Lógica de Negocio**
- Cálculos matemáticos incorrectos en reportes
- Filtros que no aplican lógica AND correctamente
- Búsquedas case-sensitive cuando deberían ser case-insensitive
- Relaciones entre entidades inconsistentes

### **Manejo de Errores**
- Códigos de estado HTTP incorrectos
- Mensajes de error genéricos o confusos
- Falta de validación de parámetros de entrada
- Excepciones no controladas que causan errores 500

### **Performance y Escalabilidad**
- Consultas lentas con grandes volúmenes de datos
- Falta de límites en parámetros de paginación
- Filtros que no usan índices de base de datos
- Memory leaks en agregaciones complejas

---

## 📝 **REPORTES DE RESULTADOS**

### **Formato de Reporte por Escenario**
```
ESCENARIO: [Nombre del escenario]
ESTADO: ✅ PASS | ❌ FAIL | ⚠️ SKIP

DATOS DE ENTRADA:
- [Especificar datos utilizados]

RESULTADO ESPERADO:
- [Comportamiento esperado según regla de negocio]

RESULTADO ACTUAL:
- [Lo que realmente ocurrió]

EVIDENCIA:
- [Screenshots, logs, responses]

OBSERVACIONES:
- [Notas adicionales o defectos encontrados]
```

### **Métricas de Calidad Final**
- **Tasa de Éxito**: % de escenarios que pasan
- **Defectos Críticos**: Impactan funcionalidad core
- **Defectos Mayores**: Afectan experiencia de usuario
- **Defectos Menores**: Mejoras cosméticas o mensajes
- **Tiempo Promedio**: Performance de respuestas de API