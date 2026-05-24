import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
// Auto-hides flash messages after a timeout and allows manual dismissal
export default class extends Controller {
  static targets = ["message"]
  static values = {
    autoHideMs: { type: Number, default: 5000 }
  }

  connect() {
    // Auto-hide flash messages after timeout
    this.timeout = setTimeout(() => {
      this.hide()
    }, this.autoHideMsValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // Manual close button
  close(event) {
    event.preventDefault()
    this.hide()
  }

  hide() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Use CSS transition for smooth fade out
    this.element.classList.add("opacity-0", "translate-y-[-10px]")
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}