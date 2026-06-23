import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "modal", "copyButton" ]
  static values = {
    url: String,
    title: String
  }

  share(event) {
    event.preventDefault()

    if (navigator.share) {
      navigator.share({
        title: this.titleValue,
        url: this.urlValue
      }).then(() => {
        // Shared successfully
      }).catch((error) => {
        // User cancelled or share failed, fallback to modal
        if (error.name !== "AbortError") {
          console.error("Error sharing:", error)
          this.openModal()
        }
      })
    } else {
      this.openModal()
    }
  }

  openModal() {
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
    }
  }

  closeModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("opacity-100")
      this.modalTarget.classList.add("opacity-0")
      
      const content = this.modalTarget.querySelector(".modal-content")
      if (content) {
        content.classList.remove("scale-100", "opacity-100")
        content.classList.add("scale-95", "opacity-0")
      }

      setTimeout(() => {
        this.modalTarget.classList.add("hidden")
        this.modalTarget.classList.remove("flex")
      }, 300)
    }
  }

  copy(event) {
    event.preventDefault()
    
    navigator.clipboard.writeText(this.urlValue).then(() => {
      if (this.hasCopyButtonTarget) {
        const originalHTML = this.copyButtonTarget.innerHTML
        this.copyButtonTarget.innerHTML = `
          <svg class="w-5 h-5 mr-2 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          ¡Copiado!
        `
        this.copyButtonTarget.classList.add("bg-emerald-50", "text-emerald-700", "border-emerald-200")
        
        setTimeout(() => {
          this.copyButtonTarget.innerHTML = originalHTML
          this.copyButtonTarget.classList.remove("bg-emerald-50", "text-emerald-700", "border-emerald-200")
        }, 2000)
      }
    }).catch(err => {
      console.error("Error al copiar al portapapeles: ", err)
    })
  }
}
