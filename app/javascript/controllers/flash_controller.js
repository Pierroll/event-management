import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    autoHideMs: { type: Number, default: 5000 }
  }

  connect() {
    // Start auto-hide timer
    this.hideTimeout = setTimeout(() => {
      this.hide()
    }, this.autoHideMsValue)
  }

  disconnect() {
    if (this.hideTimeout) clearTimeout(this.hideTimeout)
    if (this.removeTimeout) clearTimeout(this.removeTimeout)
  }

  close(event) {
    if (event) event.preventDefault()
    this.hide()
  }

  hide() {
    if (this.hideTimeout) clearTimeout(this.hideTimeout)

    // Apply exit animations
    this.element.classList.replace("opacity-100", "opacity-0")
    this.element.classList.replace("translate-y-0", "-translate-y-2")
    this.element.classList.add("pointer-events-none")
    
    // Remove from DOM after transition
    this.removeTimeout = setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}