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

  show(title, message, element) {
    this.titleTarget.textContent = title
    this.messageTarget.textContent = message
    
    // Customize UI based on action (optional, can detect keywords like "Eliminar" or "Cancelar")
    const isDanger = message.toLowerCase().includes("cancelar") || message.toLowerCase().includes("eliminar")
    const iconContainer = this.modalTarget.querySelector(".icon-container")
    const confirmBtn = this.modalTarget.querySelector("[data-action='click->confirm#confirm']")

    if (isDanger) {
      iconContainer?.classList.add("bg-error/10", "text-error")
      iconContainer?.classList.remove("bg-surface-secondary", "text-link")
      confirmBtn?.classList.add("text-error")
      confirmBtn?.classList.remove("text-link")
    } else {
      iconContainer?.classList.add("bg-surface-secondary", "text-link")
      iconContainer?.classList.remove("bg-error/10", "text-error")
      confirmBtn?.classList.add("text-link")
      confirmBtn?.classList.remove("text-error")
    }
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    
    // Smooth entry
    setTimeout(() => {
      this.modalTarget.classList.remove("opacity-0")
      this.modalTarget.classList.add("opacity-100")
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
    this.modalTarget.classList.remove("opacity-100")
    this.modalTarget.classList.add("opacity-0")
    this.modalTarget.querySelector(".modal-content").classList.replace("scale-100", "scale-95")
    this.modalTarget.querySelector(".modal-content").classList.replace("opacity-100", "opacity-0")
    
    setTimeout(() => {
      this.modalTarget.classList.remove("flex")
      this.modalTarget.classList.add("hidden")
    }, 150)
  }
}
