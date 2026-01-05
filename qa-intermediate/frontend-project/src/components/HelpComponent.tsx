import { QuestionMarkCircleIcon, ArrowLeftIcon } from '@heroicons/react/24/outline'
import { Link } from 'react-router-dom'

const HelpComponent = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex justify-center mb-6">
            <div className="bg-indigo-600 rounded-full p-4">
              <QuestionMarkCircleIcon className="h-12 w-12 text-white" />
            </div>
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Centro de Ayuda
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Encuentra respuestas a las preguntas más frecuentes sobre el Frontend Project
          </p>
        </div>

        {/* Navigation Back */}
        <div className="mb-8">
          <Link 
            to="/" 
            className="inline-flex items-center text-indigo-600 hover:text-indigo-800 font-medium"
          >
            <ArrowLeftIcon className="h-5 w-5 mr-2" />
            Volver al inicio
          </Link>
        </div>

        {/* Help Content */}
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="grid md:grid-cols-2 gap-8">
            {/* FAQ Section */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Preguntas Frecuentes
              </h2>
              <div className="space-y-4">
                <div className="border-l-4 border-indigo-500 pl-4">
                  <h3 className="font-semibold text-gray-900">¿Cómo empezar?</h3>
                  <p className="text-gray-600 mt-1">
                    Selecciona uno de los 8 retos disponibles y comienza a desarrollar tu solución.
                  </p>
                </div>
                <div className="border-l-4 border-green-500 pl-4">
                  <h3 className="font-semibold text-gray-900">¿Qué tecnologías usar?</h3>
                  <p className="text-gray-600 mt-1">
                    React 18, TypeScript, TailwindCSS, React Router, y las herramientas de testing incluidas.
                  </p>
                </div>
                <div className="border-l-4 border-purple-500 pl-4">
                  <h3 className="font-semibold text-gray-900">¿Necesito experiencia previa?</h3>
                  <p className="text-gray-600 mt-1">
                    Se recomienda conocimiento intermedio de React y TypeScript.
                  </p>
                </div>
              </div>
            </div>

            {/* Quick Links */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Enlaces Útiles
              </h2>
              <div className="space-y-3">
                <a 
                  href="https://react.dev/" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="block p-4 border border-gray-200 rounded-lg hover:border-indigo-500 hover:shadow-md transition-all"
                >
                  <h3 className="font-semibold text-indigo-600">Documentación de React</h3>
                  <p className="text-gray-600 text-sm">Guías oficiales y API reference</p>
                </a>
                <a 
                  href="https://tailwindcss.com/docs" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="block p-4 border border-gray-200 rounded-lg hover:border-indigo-500 hover:shadow-md transition-all"
                >
                  <h3 className="font-semibold text-indigo-600">TailwindCSS Docs</h3>
                  <p className="text-gray-600 text-sm">Clases de utilidad y componentes</p>
                </a>
                <a 
                  href="https://reactrouter.com/" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="block p-4 border border-gray-200 rounded-lg hover:border-indigo-500 hover:shadow-md transition-all"
                >
                  <h3 className="font-semibold text-indigo-600">React Router</h3>
                  <p className="text-gray-600 text-sm">Routing para aplicaciones React</p>
                </a>
              </div>
            </div>
          </div>

          {/* Contact Section */}
          <div className="mt-12 text-center p-6 bg-gradient-to-r from-indigo-50 to-purple-50 rounded-xl">
            <h3 className="text-xl font-bold text-gray-900 mb-2">
              ¿Necesitas más ayuda?
            </h3>
            <p className="text-gray-600 mb-4">
              Si no encuentras la respuesta que buscas, no dudes en contactarnos.
            </p>
            <button className="bg-indigo-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-indigo-700 transition-colors">
              Contactar Soporte
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default HelpComponent
