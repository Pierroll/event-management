import { Controller } from "@hotwired/stimulus"

// Custom confirmation modal for Turbo
export default class extends Controller {
  static targets = ["modal", "title", "message", "confirmButton"]

  connect() {
    // Override Turbo's default confirm method
    Turbo.setConfirmMethod((message, element) => {
      let title = element.dataset.turboConfirmTitle || "Confirmar acción"
      return this.show(title, message)
    })
  }

  show(title, message) {
    this.titleTarget.textContent = title
    this.messageTarget.textContent = message
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    
    // Smooth entry
    setTimeout(() => {
      this.modalTarget.querySelector(".modal-content").classList.remove("scale-95", "opacity-0")
      this.modalTarget.querySelector(".modal-content").classList.add("scale-100", "opacity-100")
    }, 10)

    return new Promise((resolve) => {
      this.resolve = resolve
    })
  }

  confirm() {
    this.hide()
    this.resolve(true)
  }

  cancel() {
    this.hide()
    this.resolve(false)
  }

  hide() {
    this.modalTarget.querySelector(".modal-content").classList.replace("scale-100", "scale-95")
    this.modalTarget.querySelector(".modal-content").classList.replace("opacity-100", "opacity-0")
    
    setTimeout(() => {
      this.modalTarget.classList.replace("flex", "hidden")
    }, 200)
  }
}
