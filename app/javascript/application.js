// Entry point for SGE Event Management
// Configure Stimulus and Turbo
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

// Acelerar la barra de progreso de Turbo para que aparezca casi instantáneamente (100ms)
Turbo.setProgressBarDelay(100)

// Estados de carga (loaders) globales para botones de envío
document.addEventListener("turbo:submit-start", (event) => {
  const submitter = event.detail.formSubmission.submitter
  if (submitter) {
    submitter.disabled = true
    submitter.dataset.originalText = submitter.innerHTML
    
    // Inyectar un spinner SVG giratorio con diseño alineado
    submitter.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Procesando...
    `
  }
})

document.addEventListener("turbo:submit-end", (event) => {
  const submitter = event.detail.formSubmission.submitter
  if (submitter && submitter.dataset.originalText) {
    submitter.disabled = false
    submitter.innerHTML = submitter.dataset.originalText
  }
})