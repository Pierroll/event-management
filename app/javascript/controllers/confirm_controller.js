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
      iconContainer?.classList.add("bg-rose-50", "text-rose-500")
      iconContainer?.classList.remove("bg-blue-50", "text-blue-500")
      confirmBtn?.classList.add("text-rose-600")
      confirmBtn?.classList.remove("text-blue-600")
    } else {
      iconContainer?.classList.add("bg-blue-50", "text-blue-500")
      iconContainer?.classList.remove("bg-rose-50", "text-rose-500")
      confirmBtn?.classList.add("text-blue-600")
      confirmBtn?.classList.remove("text-rose-600")
    }
    
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
