import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-form"
// Maneja uploads de imagen con distinción principal/secundaria, drag-and-drop, preview y validación.
//
// Protocolo de campos:
//   Modo CREATE (existingCount === 0):
//     • Primer archivo  → event[primary_image]  (file input separado)
//     • Resto archivos  → event[images][]       (file input múltiple)
//     • Primer URL      → event[primary_image]  (hidden field)
//     • Resto URLs      → event[images][]       (hidden fields)
//   Modo EDIT (existingCount > 0):
//     • Todos los nuevos archivos → event[images][]
//     • IDs a eliminar            → event[remove_image_ids][]
//
export default class extends Controller {
  static targets = [
    "dropzone", "fileInput", "primaryFileInput", "previewContainer",
    "filePane", "urlPane", "urlInput", "statusInput"
  ]

  // ──────────────────────────────────────────────────────────────────────────────
  // ESTADO
  // ──────────────────────────────────────────────────────────────────────────────
  connect() {
    this.newFiles    = []   // Files nuevos elegidos por el usuario
    this.newUrls     = []   // URLs nuevas ingresadas por el usuario
    this.removedIds  = []   // IDs de imágenes existentes a eliminar
    this.MAX_TOTAL   = 5

    // Leer imágenes existentes del DOM (renderizadas por ERB en modo edit)
    this.existingCount = parseInt(this.element.dataset.existingImagesCount || "0")
  }

  get currentTotal() {
    return (this.existingCount - this.removedIds.length) + this.newFiles.length + this.newUrls.length
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // ESTADO: SUBMIT
  // ──────────────────────────────────────────────────────────────────────────────
  setStatus(event) {
    const status = event.currentTarget.dataset.status
    if (this.hasStatusInputTarget) {
      this.statusInputTarget.value = status
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // TABS
  // ──────────────────────────────────────────────────────────────────────────────
  showTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.filePaneTarget.classList.toggle("hidden", tab !== "file")
    this.urlPaneTarget.classList.toggle("hidden", tab !== "url")

    event.currentTarget.parentElement.querySelectorAll("button[data-tab]").forEach(btn => {
      const active = btn.dataset.tab === tab
      btn.classList.toggle("text-link", active)
      btn.classList.toggle("border-b-2", active)
      btn.classList.toggle("border-primary", active)
      btn.classList.toggle("pb-[14px]", active)
      btn.classList.toggle("-mb-[18px]", active)
      btn.classList.toggle("text-muted", !active)
    })
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // DRAG & DROP / FILE PICKER
  // ──────────────────────────────────────────────────────────────────────────────
  browse()   { this.fileInputTarget.click() }

  dragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-primary", "bg-surface-secondary/50")
  }

  dragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary", "bg-surface-secondary/50")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary", "bg-surface-secondary/50")
    this.processFiles(Array.from(event.dataTransfer.files))
  }

  fileChange(event) {
    const files = Array.from(event.target.files)
    // Reset file input first so same file can be re-selected,
    // and to prevent clearing the files assigned in syncHiddenFields().
    event.target.value = ""
    this.processFiles(files)
  }

  processFiles(fileArray) {
    for (const file of fileArray) {
      if (this.currentTotal >= this.MAX_TOTAL) {
        this.flash(`Máximo ${this.MAX_TOTAL} imágenes en total.`)
        break
      }
      if (!file.type.startsWith("image/")) {
        this.flash(`"${file.name}" no es una imagen válida.`)
        continue
      }
      if (file.size > 5 * 1024 * 1024) {
        this.flash(`"${file.name}" supera 5MB.`)
        continue
      }
      this.newFiles.push(file)
    }
    this.syncHiddenFields()
    this.renderNewPreviews()
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // URL
  // ──────────────────────────────────────────────────────────────────────────────
  addFromUrl() {
    const url = this.urlInputTarget.value.trim()
    if (!url) return
    if (this.currentTotal >= this.MAX_TOTAL) {
      this.flash(`Máximo ${this.MAX_TOTAL} imágenes en total.`)
      return
    }
    this.newUrls.push(url)
    this.urlInputTarget.value = ""
    this.syncHiddenFields()
    this.renderNewPreviews()
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // ELIMINACIÓN
  // ──────────────────────────────────────────────────────────────────────────────

  // Eliminar imagen EXISTENTE (guardada en BD) — agrega ID a lista de removidos
  removeExisting(event) {
    event.preventDefault()
    const card = event.currentTarget.closest("[data-image-id]")
    if (!card) return

    const imageId = card.dataset.imageId
    this.removedIds.push(imageId)

    // Agregar hidden field para enviar el ID al backend
    this.addHiddenField("event[remove_image_ids][]", imageId)

    // Animación de salida y eliminación del DOM
    card.style.transition = "opacity 0.25s, transform 0.25s"
    card.style.opacity = "0"
    card.style.transform = "scale(0.9)"
    setTimeout(() => {
      card.remove()
      this.existingCount--
      this.refreshPrimaryBadge()
    }, 250)
  }

  // Eliminar imagen NUEVA (archivo local)
  removeNewFile(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.fileIndex)
    this.newFiles.splice(index, 1)
    this.syncHiddenFields()
    this.renderNewPreviews()
  }

  // Eliminar URL nueva
  removeNewUrl(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.urlIndex)
    this.newUrls.splice(index, 1)
    this.syncHiddenFields()
    this.renderNewPreviews()
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // RENDER PREVIEWS (solo para imágenes NUEVAS — las existentes las renderiza ERB)
  // ──────────────────────────────────────────────────────────────────────────────
  renderNewPreviews() {
    // Limpiar solo las previews "nuevas" (no las existentes renderizadas por ERB)
    this.previewContainerTarget.querySelectorAll("[data-new-preview]").forEach(el => el.remove())

    const existingRemaining = this.existingCount - this.removedIds.length
    let slotIndex = existingRemaining // posición global

    // Archivos nuevos
    this.newFiles.forEach((file, i) => {
      const isMain = slotIndex === 0
      const reader = new FileReader()
      reader.onload = (e) => {
        const card = this.buildPreviewCard(e.target.result, isMain, "file", i, null)
        this.previewContainerTarget.appendChild(card)
      }
      reader.readAsDataURL(file)
      slotIndex++
    })

    // URLs nuevas
    this.newUrls.forEach((url, i) => {
      const isMain = slotIndex === 0
      const card = this.buildPreviewCard(url, isMain, "url", null, i)
      this.previewContainerTarget.appendChild(card)
      slotIndex++
    })
  }

  buildPreviewCard(src, isPrimary, type, fileIndex, urlIndex) {
    const wrap = document.createElement("div")
    wrap.dataset.newPreview = "true"
    wrap.className = `group relative aspect-square bg-surface-secondary rounded-card overflow-hidden border-2 transition-all ${
      isPrimary ? "border-primary ring-2 ring-primary/30" : "border-border"
    }`

    // Imagen
    const img = document.createElement("img")
    img.src = src
    img.className = "w-full h-full object-cover"
    wrap.appendChild(img)

    // Botón eliminar
    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "absolute top-2 right-2 bg-black/60 text-white rounded-full w-7 h-7 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:bg-rose-500"
    btn.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>`

    if (type === "file") {
      btn.dataset.fileIndex = fileIndex
      btn.addEventListener("click", (e) => this.removeNewFile(e))
    } else {
      btn.dataset.urlIndex = urlIndex
      btn.addEventListener("click", (e) => this.removeNewUrl(e))
    }
    wrap.appendChild(btn)

    // Badge
    const badge = document.createElement("div")
    if (isPrimary) {
      badge.className = "absolute bottom-2 left-2 flex items-center gap-1 px-2 py-0.5 bg-primary text-[9px] font-bold text-white uppercase tracking-widest rounded-input"
      badge.innerHTML = `<svg class="w-3 h-3 shrink-0" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>Principal`
    } else {
      badge.className = "absolute bottom-2 left-2 px-2 py-0.5 bg-black/40 backdrop-blur-sm text-[9px] font-bold text-white uppercase tracking-widest rounded-md"
      badge.textContent = type === "file" ? "Local" : "URL"
    }
    wrap.appendChild(badge)

    return wrap
  }

  // Cuando se elimina una imagen existente, puede que la primera nueva pase a ser principal
  refreshPrimaryBadge() {
    this.renderNewPreviews()
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // SYNC HIDDEN FIELDS (mantiene inputs sincronizados con el estado JS)
  // ──────────────────────────────────────────────────────────────────────────────
  syncHiddenFields() {
    const existingRemaining = this.existingCount - this.removedIds.length
    const isCreateMode = existingRemaining === 0

    // Limpiar campos hidden dinámicos previos
    this.element.querySelectorAll("[data-dynamic-field]").forEach(el => el.remove())

    if (isCreateMode && this.newFiles.length > 0) {
      // CREATE: primer archivo → primary_image, resto → images[]
      const [primaryFile, ...secondaryFiles] = this.newFiles

      // primary_image en su propio input (event[primary_image])
      if (this.hasPrimaryFileInputTarget) {
        const dtPrimary = new DataTransfer()
        dtPrimary.items.add(primaryFile)
        this.primaryFileInputTarget.files = dtPrimary.files
      }

      // images[] para los secundarios
      const dtSecondary = new DataTransfer()
      secondaryFiles.forEach(f => dtSecondary.items.add(f))
      this.fileInputTarget.files = dtSecondary.files
    } else {
      // EDIT: todos los archivos nuevos van como images[]
      if (this.hasPrimaryFileInputTarget) {
        this.primaryFileInputTarget.files = new DataTransfer().files
      }
      const dt = new DataTransfer()
      this.newFiles.forEach(f => dt.items.add(f))
      this.fileInputTarget.files = dt.files
    }

    // URLs
    this.newUrls.forEach((url, i) => {
      const isPrimaryUrl = isCreateMode && this.newFiles.length === 0 && i === 0
      this.addHiddenField(isPrimaryUrl ? "event[primary_image]" : "event[images][]", url)
    })
  }

  addHiddenField(name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    input.dataset.dynamicField = "true"
    this.element.appendChild(input)
    return input
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // UTILS
  // ──────────────────────────────────────────────────────────────────────────────
  flash(message) {
    window.dispatchEvent(new CustomEvent("flash:show", { detail: { type: "error", message } }))
  }
}