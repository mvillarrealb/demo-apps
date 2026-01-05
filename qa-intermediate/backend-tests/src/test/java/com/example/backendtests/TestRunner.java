package com.example.backendtests;

import com.intuit.karate.junit5.Karate;

/**
 * TestRunner para ejecutar todas las pruebas de Karate DSL.
 * Este runner utiliza JUnit 5 para ejecutar los features de Karate.
 */
public class TestRunner {

    /**
     * Ejecuta todas las pruebas Karate en el classpath
     * @return Karate builder configurado
     */
    @Karate.Test
    Karate testAll() {
        return Karate.run().relativeTo(getClass());
    }

    /**
     * Ejecuta solo las pruebas de todos (TODOs)
     * @return Karate builder configurado para pruebas de todos
     */
    @Karate.Test
    Karate testTodos() {
        return Karate.run("classpath:features/todos").relativeTo(getClass());
    }

    /**
     * Ejecuta pruebas con tags específicos
     * Ejemplo de uso: mvn test -Dkarate.options="--tags @smoke"
     * @return Karate builder configurado con tags
     */
    @Karate.Test
    Karate testSmoke() {
        return Karate.run().tags("@smoke").relativeTo(getClass());
    }

    /**
     * Ejecuta pruebas en paralelo (comentado por defecto)
     * Para habilitar el paralelismo, descomenta este método y comenta los anteriores
     */
    /*
    @Karate.Test
    Karate testParallel() {
        return Karate.run().tags("~@ignore").parallel(2);
    }
    */
}