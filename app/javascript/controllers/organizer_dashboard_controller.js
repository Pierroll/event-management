import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="organizer-dashboard"
// Handles inline publish/cancel actions for organizer events
export default class extends Controller {
  static targets = ["eventRow"]

  // Publish a draft event
  publish(event) {
    const eventId = event.params.eventId
    if (!eventId) return

    if (!confirm("¿Estás seguro de que deseas publicar este evento? Será visible para todos los usuarios.")) {
      return
    }

    this.submitStatusForm(eventId, "published")
  }

  // Cancel an event
  cancel(event) {
    const eventId = event.params.eventId
    if (!eventId) return

    if (!confirm("¿Estás seguro de que deseas cancelar este evento? Esta acción no se puede deshacer.")) {
      return
    }

    this.submitStatusForm(eventId, "canceled")
  }

  // Submit a Turbo form to update event status
  submitStatusForm(eventId, status) {
    // Find the form for this specific event
    const form = this.element.querySelector(`[data-event-id="${eventId}"][data-action="organizer-dashboard#updateStatus"]`)
    if (form) {
      const statusInput = form.querySelector("input[name='event[status]']")
      if (statusInput) {
        statusInput.value = status
      }
      // Turbo will handle the form submission via Turbo Streams
      form.requestSubmit()
    }
  }
}