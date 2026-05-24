import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-form"
// Handles drag-and-drop image uploads, previews, and client-side validation
export default class extends Controller {
  static targets = ["dropzone", "fileInput", "previewContainer", "errorContainer"]

  connect() {
    this.attachedFiles = []
  }

  // Drag over visual feedback
  dragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50")
    }
  }

  dragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50")
    }
  }

  // Handle dropped files
  drop(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50")
    }

    const files = event.dataTransfer.files
    this.handleFiles(files)
  }

  // Handle file input change
  fileChange(event) {
    const files = event.target.files
    this.handleFiles(files)
  }

  // Process and validate files
  handleFiles(files) {
    const fileArray = Array.from(files)
    const imageFiles = fileArray.filter(file => file.type.startsWith("image/"))

    if (imageFiles.length !== fileArray.length) {
      this.showError("Solo se permiten archivos de imagen.")
      return
    }

    this.attachedFiles = [...this.attachedFiles, ...imageFiles]
    this.renderPreviews()

    // Update the file input for Rails form submission
    this.updateFileInput()
  }

  // Remove a file from the queue
  removeFile(event) {
    const index = parseInt(event.params.index)
    this.attachedFiles.splice(index, 1)
    this.renderPreviews()
    this.updateFileInput()
  }

  // Render image previews
  renderPreviews() {
    if (!this.hasPreviewContainerTarget) return

    this.previewContainerTarget.innerHTML = ""

    this.attachedFiles.forEach((file, index) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const wrapper = document.createElement("div")
        wrapper.className = "relative inline-block m-1"

        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "w-24 h-24 object-cover rounded-lg border border-gray-200"

        const removeBtn = document.createElement("button")
        removeBtn.type = "button"
        removeBtn.className = "absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 text-xs flex items-center justify-center hover:bg-red-600"
        removeBtn.innerHTML = "&times;"
        removeBtn.dataset.action = "click->event-form#removeFile"
        removeBtn.dataset.eventFormIndexParam = index

        wrapper.appendChild(img)
        wrapper.appendChild(removeBtn)
        this.previewContainerTarget.appendChild(wrapper)
      }
      reader.readAsDataURL(file)
    })
  }

  // Update the hidden file input for Rails
  // Rails handles multiple file uploads via Active Storage
  updateFileInput() {
    if (!this.hasFileInputTarget) return

    // Create a new FileList-compatible data transfer
    const dt = new DataTransfer()
    this.attachedFiles.forEach(file => dt.items.add(file))
    this.fileInputTarget.files = dt.files
  }

  // Client-side validation before form submit
  validate(event) {
    const form = event.target
    let isValid = true
    const errors = []

    const name = form.querySelector("#event_name")?.value
    const description = form.querySelector("#event_description")?.value
    const city = form.querySelector("#event_city")?.value
    const address = form.querySelector("#event_address")?.value
    const startDate = form.querySelector("#event_start_date")?.value
    const price = form.querySelector("#event_price")?.value
    const categoryId = form.querySelector("#event_category_id")?.value

    if (!name || name.trim() === "") {
      errors.push("El nombre del evento es obligatorio.")
      isValid = false
    }

    if (!description || description.trim() === "") {
      errors.push("La descripción es obligatoria.")
      isValid = false
    }

    if (!city || city.trim() === "") {
      errors.push("La ciudad es obligatoria.")
      isValid = false
    }

    if (!address || address.trim() === "") {
      errors.push("La dirección es obligatoria.")
      isValid = false
    }

    if (!startDate) {
      errors.push("La fecha de inicio es obligatoria.")
      isValid = false
    }

    if (price && parseFloat(price) < 0) {
      errors.push("El precio no puede ser negativo.")
      isValid = false
    }

    if (!categoryId) {
      errors.push("La categoría es obligatoria.")
      isValid = false
    }

    if (!isValid) {
      event.preventDefault()
      this.showErrors(errors)
    }
  }

  showError(message) {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.innerHTML = `<p class="text-red-500 text-sm">${message}</p>`
      setTimeout(() => {
        this.errorContainerTarget.innerHTML = ""
      }, 3000)
    }
  }

  showErrors(errors) {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.innerHTML = `
        <div class="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
          <ul class="list-disc list-inside text-red-600 text-sm">
            ${errors.map(e => `<li>${e}</li>`).join("")}
          </ul>
        </div>
      `
      this.errorContainerTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }
}