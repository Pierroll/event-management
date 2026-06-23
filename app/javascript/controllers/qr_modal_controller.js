import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "modal" ]

  connect() {
    this.escHandler = (e) => {
      if (e.key === "Escape" && this.isOpen()) {
        this.close()
      }
    }
    window.addEventListener("keydown", this.escHandler)
  }

  disconnect() {
    window.removeEventListener("keydown", this.escHandler)
  }

  isOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains("hidden")
  }

  open(event) {
    if (event) event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      // Force reflow
      this.modalTarget.offsetHeight
      this.modalTarget.classList.add("flex")
      this.modalTarget.classList.remove("opacity-0")
      this.modalTarget.classList.add("opacity-100")

      const content = this.modalTarget.querySelector(".modal-content")
      if (content) {
        content.classList.remove("scale-95", "opacity-0")
        content.classList.add("scale-100", "opacity-100")
      }
      document.body.style.overflow = "hidden"
    }
  }

  close(event) {
    if (event) event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("opacity-100")
      this.modalTarget.classList.add("opacity-0")

      const content = this.modalTarget.querySelector(".modal-content")
      if (content) {
        content.classList.remove("scale-100", "opacity-100")
        content.classList.add("scale-95", "opacity-0")
      }

      document.body.style.overflow = ""

      setTimeout(() => {
        this.modalTarget.classList.add("hidden")
        this.modalTarget.classList.remove("flex")
      }, 300)
    }
  }
}
