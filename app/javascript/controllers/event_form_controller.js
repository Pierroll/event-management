import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-form"
// Handles drag-and-drop image uploads, previews, and client-side validation
export default class extends Controller {
  static targets = ["dropzone", "fileInput", "previewContainer", "errorContainer", "filePane", "urlPane", "urlInput", "statusInput"]

  connect() {
    this.attachedFiles = []
    this.urlImages = []
  }

  // Set status before submit
  setStatus(event) {
    const status = event.currentTarget.dataset.status
    if (this.hasStatusInputTarget) {
      this.statusInputTarget.value = status
      console.log("Setting status to:", status)
    }
  }

  // Tab Switching Logic
  showTab(event) {
    const tab = event.currentTarget.dataset.tab
    
    // Toggle Panes
    this.filePaneTarget.classList.toggle("hidden", tab !== "file")
    this.urlPaneTarget.classList.toggle("hidden", tab !== "url")

    // Toggle Button Styles
    event.currentTarget.parentElement.querySelectorAll("button").forEach(btn => {
      if (btn.dataset.tab === tab) {
        btn.classList.add("text-blue-600", "border-b-2", "border-blue-600", "pb-4", "-mb-4.5")
        btn.classList.remove("text-gray-400")
      } else {
        btn.classList.remove("text-blue-600", "border-b-2", "border-blue-600", "pb-4", "-mb-4.5")
        btn.classList.add("text-gray-400")
      }
    })
  }

  // Open file browser when clicking the dropzone
  browse() {
    this.fileInputTarget.click()
  }

  dragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-blue-500", "bg-white")
  }

  dragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-white")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-white")
    this.handleFiles(event.dataTransfer.files)
  }

  fileChange(event) {
    this.handleFiles(event.target.files)
  }

  handleFiles(files) {
    const fileArray = Array.from(files)
    const maxSize = 5 * 1024 * 1024 // 5MB

    const validFiles = fileArray.filter(file => {
      if (!file.type.startsWith("image/")) {
        this.showError(`"${file.name}" no es una imagen válida.`)
        return false
      }
      if (file.size > maxSize) {
        this.showError(`"${file.name}" excede el límite de 5MB.`)
        return false
      }
      return true
    })

    this.attachedFiles = [...this.attachedFiles, ...validFiles]
    this.renderPreviews()
    this.updateHiddenFields()
  }

  addFromUrl() {
    const url = this.urlInputTarget.value.trim()
    if (url === "") return

    if (!url.match(/\.(jpeg|jpg|gif|png|webp)$/i) && !url.includes("images.unsplash.com")) {
      this.showError("El enlace no parece ser una imagen válida.")
      return
    }

    this.urlImages.push(url)
    this.urlInputTarget.value = ""
    this.renderPreviews()
    this.updateHiddenFields()
  }

  removeFile(event) {
    const index = parseInt(event.params.index)
    this.attachedFiles.splice(index, 1)
    this.renderPreviews()
    this.updateHiddenFields()
  }

  removeUrl(event) {
    const index = parseInt(event.params.index)
    this.urlImages.splice(index, 1)
    this.renderPreviews()
    this.updateHiddenFields()
  }

  renderPreviews() {
    this.previewContainerTarget.innerHTML = ""

    // Render Local Files
    this.attachedFiles.forEach((file, index) => {
      const reader = new FileReader()
      reader.onload = (e) => this.appendPreview(e.target.result, index, "file")
      reader.readAsDataURL(file)
    })

    // Render URL Images
    this.urlImages.forEach((url, index) => {
      this.appendPreview(url, index, "url")
    })
  }

  appendPreview(src, index, type) {
    const wrapper = document.createElement("div")
    wrapper.className = "group relative aspect-square bg-gray-100 rounded-xl overflow-hidden border border-gray-200"

    const img = document.createElement("img")
    img.src = src
    img.className = "w-full h-full object-cover"

    const removeBtn = document.createElement("button")
    removeBtn.type = "button"
    removeBtn.className = "absolute top-2 right-2 bg-black/50 backdrop-blur-md text-white rounded-full w-7 h-7 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:bg-rose-500"
    removeBtn.innerHTML = `
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    `
    removeBtn.dataset.action = type === "file" ? "click->event-form#removeFile" : "click->event-form#removeUrl"
    removeBtn.dataset.eventFormIndexParam = index

    const badge = document.createElement("div")
    badge.className = "absolute bottom-2 left-2 px-2 py-0.5 bg-black/40 backdrop-blur-md text-[8px] font-bold text-white uppercase tracking-widest rounded"
    badge.innerText = type === "file" ? "Local" : "URL"

    wrapper.appendChild(img)
    wrapper.appendChild(removeBtn)
    wrapper.appendChild(badge)
    this.previewContainerTarget.appendChild(wrapper)
  }

  updateHiddenFields() {
    // Update real file input
    const dt = new DataTransfer()
    this.attachedFiles.forEach(file => dt.items.add(file))
    this.fileInputTarget.files = dt.files

    // Handle URL inputs - We'll append hidden fields for each URL
    // Remove old hidden url fields first
    this.element.querySelectorAll('input[name="event[images][]"][type="hidden"]').forEach(el => el.remove())
    
    this.urlImages.forEach(url => {
      const hiddenInput = document.createElement("input")
      hiddenInput.type = "hidden"
      hiddenInput.name = "event[images][]"
      hiddenInput.value = url
      this.element.appendChild(hiddenInput)
    })
  }

  showError(message) {
    // Usamos el sistema de notificaciones que ya tenemos
    const flashEvent = new CustomEvent("flash:show", { 
      detail: { type: "error", message: message }
    })
    window.dispatchEvent(flashEvent)
  }

  validate(event) {
    // ... lógica de validación anterior mantenida ...
  }
}