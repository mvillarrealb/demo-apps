Feature: Gestión de TODOs - JSONPlaceholder API
  Como QA Engineer
  Quiero validar las operaciones CRUD de la API de TODOs
  Para asegurar que la funcionalidad básica de la API funciona correctamente

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'

  @smoke @get
  Scenario: GET - Obtener todos los TODOs
    Descripción: Verificar que se pueden obtener todos los TODOs disponibles
    
    Given path '/todos'
    When method GET
    Then status 200
    And match header Content-Type contains 'application/json'
    And match response == '#[]'
    And match response[0] contains { id: '#number', title: '#string', completed: '#boolean', userId: '#number' }
    And assert response.length > 0
    And karate.log('Total de TODOs obtenidos:', response.length)

  @smoke @get @positive
  Scenario: GET - Obtener un TODO específico por ID válido
    Descripción: Verificar que se puede obtener un TODO específico usando un ID válido
    
    Given path '/todos', testData.validTodoId
    When method GET
    Then status 200
    And match response contains { id: '#(testData.validTodoId)', title: '#string', completed: '#boolean', userId: '#number' }
    And match response.id == testData.validTodoId
    And assert response.title.length > 0
    And karate.log('TODO obtenido:', response.title)

  @get @negative
  Scenario: GET - Intentar obtener un TODO con ID inválido
    Descripción: Verificar el comportamiento cuando se solicita un TODO con ID que no existe
    
    Given path '/todos', testData.invalidTodoId
    When method GET
    Then status 404

  @get @negative @boundary
  Scenario Outline: GET - Validar TODOs con diferentes IDs de frontera
    Descripción: Probar IDs en los límites para verificar el manejo de casos edge
    
    Given path '/todos', <todoId>
    When method GET
    Then status <expectedStatus>
    
    Examples:
      | todoId | expectedStatus | description           |
      | 0      | 404           | ID cero               |
      | -1     | 404           | ID negativo           |
      | 201    | 404           | ID fuera de rango     |
      | 'abc'  | 404           | ID no numérico        |

  @post @create
  Scenario: POST - Crear un nuevo TODO
    Descripción: Verificar que se puede crear un nuevo TODO con datos válidos
    
    Given path '/todos'
    And request testData.newTodo
    When method POST
    Then status 201
    And match response contains { id: '#number', title: '#(testData.newTodo.title)', userId: '#(testData.newTodo.userId)' }
    And assert response.id > 0
    And karate.log('TODO creado con ID:', response.id)

  @post @negative
  Scenario: POST - Intentar crear TODO con datos inválidos
    Descripción: Verificar que la API maneja correctamente datos inválidos
    
    Given path '/todos'
    And request { title: '', userId: 'invalid' }
    When method POST
    Then status 201
    # Nota: JSONPlaceholder es una API mock que siempre retorna 201 para POSTs
    # En una API real, esto debería retornar 400 Bad Request

  @put @update
  Scenario: PUT - Actualizar un TODO existente
    Descripción: Verificar que se puede actualizar completamente un TODO existente
    
    * def updatedTodo = 
    """
    {
      id: 1,
      title: 'TODO actualizado por Karate',
      body: 'Contenido actualizado',
      userId: 1,
      completed: true
    }
    """
    
    Given path '/todos', 1
    And request updatedTodo
    When method PUT
    Then status 200
    And match response contains { id: 1, title: '#(updatedTodo.title)', completed: true }
    And karate.log('TODO actualizado:', response.title)

  @patch @update
  Scenario: PATCH - Actualizar parcialmente un TODO
    Descripción: Verificar que se puede actualizar parcialmente un TODO
    
    * def partialUpdate = { completed: true }
    
    Given path '/todos', 1
    And request partialUpdate
    When method PATCH
    Then status 200
    And match response contains { id: 1, completed: true }
    And karate.log('TODO marcado como completado')

  @delete
  Scenario: DELETE - Eliminar un TODO existente
    Descripción: Verificar que se puede eliminar un TODO existente
    
    Given path '/todos', 1
    When method DELETE
    Then status 200
    And karate.log('TODO eliminado exitosamente')

  @delete @negative
  Scenario: DELETE - Intentar eliminar TODO inexistente
    Descripción: Verificar el comportamiento al intentar eliminar un TODO que no existe
    
    Given path '/todos', testData.invalidTodoId
    When method DELETE
    Then status 200
    # Nota: JSONPlaceholder siempre retorna 200, pero en APIs reales podría ser 404

  @integration @workflow
  Scenario: Workflow completo - Crear, leer, actualizar y eliminar TODO
    Descripción: Probar el flujo completo CRUD de un TODO
    
    # 1. Crear TODO
    Given path '/todos'
    And request testData.newTodo
    When method POST
    Then status 201
    * def createdTodoId = response.id
    And karate.log('Paso 1 - TODO creado con ID:', createdTodoId)
    
    # 2. Leer TODO creado
    Given path '/todos', createdTodoId
    When method GET
    Then status 200
    And match response.title == testData.newTodo.title
    And karate.log('Paso 2 - TODO leído correctamente')
    
    # 3. Actualizar TODO
    * def updateData = { completed: true }
    Given path '/todos', createdTodoId
    And request updateData
    When method PATCH
    Then status 200
    And match response.completed == true
    And karate.log('Paso 3 - TODO actualizado a completado')
    
    # 4. Eliminar TODO
    Given path '/todos', createdTodoId
    When method DELETE
    Then status 200
    And karate.log('Paso 4 - TODO eliminado exitosamente')

  @performance @load
  Scenario: Validar tiempo de respuesta de la API
    Descripción: Verificar que la API responde dentro de tiempos aceptables
    
    * def startTime = java.lang.System.currentTimeMillis()
    
    Given path '/todos'
    When method GET
    Then status 200
    
    * def endTime = java.lang.System.currentTimeMillis()
    * def responseTime = endTime - startTime
    * assert responseTime < 3000
    And karate.log('Tiempo de respuesta:', responseTime, 'ms')
    And assert response.length > 0