import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reader", "manualInput", "statsUsed", "statsTotal", "searchResults"]
  static values = { url: String }

  connect() {
    this.processedQrs = new Set()
    this.initializeScanner()
  }

  disconnect() {
    this.stopScanner()
  }

  initializeScanner() {
    if (typeof Html5Qrcode === 'undefined') {
      this.readerTarget.innerHTML = '<p class="text-error text-sm">Error: Librería de cámara no cargada.</p>'
      return
    }

    this.scanner = new Html5Qrcode(this.readerTarget.id)
    Html5Qrcode.getCameras().then(cameras => {
      if (cameras && cameras.length > 0) {
        this.startScanner()
      } else {
        this.readerTarget.innerHTML = '<p class="text-muted text-sm">No se detectó cámara. Usá el ingreso manual.</p>'
      }
    }).catch(err => {
      console.error("Camera access error:", err)
      this.readerTarget.innerHTML = '<p class="text-muted text-sm">Permiso de cámara denegado. Usá el ingreso manual.</p>'
    })
  }

  startScanner() {
    this.scanner.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: { width: 250, height: 250 } },
      (decodedText) => {
        // Pause scanning while processing to avoid multiple reads
        if (this.scanner && typeof this.scanner.pause === 'function') {
          this.scanner.pause(true)
        }
        this.processQR(decodedText)
      },
      () => { /* no-op: scanning in progress */ }
    ).catch(err => {
      console.error("Scanner start error:", err)
      this.readerTarget.innerHTML = '<p class="text-error text-sm">No se pudo acceder a la cámara. Usá el ingreso manual.</p>'
    })
  }

  stopScanner() {
    if (this.scanner) {
      this.scanner.stop().catch(err => console.error("Error stopping scanner:", err))
    }
  }

  processQR(code) {
    if (this.processedQrs.has(code)) {
      console.log("Ignorando QR repetido en esta sesión:", code)
      // Resume scanner immediately
      setTimeout(() => {
        if (this.scanner && typeof this.scanner.resume === 'function') {
          try {
            this.scanner.resume()
          } catch(e) {}
        }
      }, 500)
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ qr_code: code })
    })
    .then(response => {
      if (response.status === 200) {
        return response.json().then(data => ({ success: true, ...data }))
      } else {
        return response.json().then(data => ({ success: false, status: response.status, ...data }))
      }
    })
    .then(payload => {
      if (payload.success) {
        this.processedQrs.add(code)
      }
      this.showResult(payload)
    })
    .catch(err => {
      console.error("Fetch error:", err)
      this.showResult({ success: false, error: 'Error de conexión' })
    })
  }

  showResult(payload) {
    // Remove existing overlay if any
    const existingOverlay = this.readerTarget.querySelector(".scanner-overlay")
    if (existingOverlay) existingOverlay.remove()

    // Create the overlay container
    const overlay = document.createElement("div")
    overlay.className = "scanner-overlay absolute inset-0 z-50 flex flex-col items-center justify-center p-6 transition-all duration-300 opacity-0 scale-95 rounded-badge"
    
    if (payload.success) {
      overlay.classList.add("bg-emerald-500/90", "backdrop-blur-sm", "text-white")
      overlay.innerHTML = `
        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mb-3">
          <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path>
          </svg>
        </div>
        <h3 class="text-lg font-black tracking-wide uppercase">Ingreso Registrado</h3>
        <p class="text-xs font-bold text-emerald-100 mt-1 text-center truncate max-w-full">${payload.attendee_name || 'Asistente'}</p>
      `

      if (payload.stats) {
        if (this.hasStatsUsedTarget) this.statsUsedTarget.textContent = payload.stats.used
        if (this.hasStatsTotalTarget) this.statsTotalTarget.textContent = payload.stats.total
      }

      // Flash body green
      document.body.classList.add('flash-success')
      setTimeout(() => document.body.classList.remove('flash-success'), 800)
    } else {
      overlay.classList.add("bg-rose-600/90", "backdrop-blur-sm", "text-white")
      overlay.innerHTML = `
        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mb-3">
          <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </div>
        <h3 class="text-lg font-black tracking-wide uppercase">Error de Ingreso</h3>
        <p class="text-xs font-bold text-rose-100 mt-1 text-center max-w-full">${payload.error || 'Error'}</p>
      `

      // Flash body red
      document.body.classList.add('flash-error')
      setTimeout(() => document.body.classList.remove('flash-error'), 800)
    }

    // Append overlay to the reader target (it's relative)
    this.readerTarget.appendChild(overlay)

    // Trigger reflow & transition in
    overlay.offsetHeight
    overlay.classList.remove("opacity-0", "scale-95")
    overlay.classList.add("opacity-100", "scale-100")

    // Auto-resume and fade out after 2 seconds
    setTimeout(() => {
      overlay.classList.remove("opacity-100", "scale-100")
      overlay.classList.add("opacity-0", "scale-95")

      setTimeout(() => {
        overlay.remove()
        if (this.scanner && typeof this.scanner.resume === 'function') {
          try {
            this.scanner.resume()
          } catch(e) {
            console.warn("Could not resume scanner state:", e)
          }
        }
      }, 300)
    }, 2000)
  }

  // Fallback manual checks
  manualCheckin(event) {
    if (event) event.preventDefault()
    const input = this.manualInputTarget
    const code = input.value.trim()
    if (!code) return
    this.processQR(code)
    input.value = ''
  }

  manualKeydown(event) {
    if (event.key === 'Enter') {
      this.manualCheckin(event)
    }
  }

  // Step 5: search tickets by attendee name or email with debounce
  search(event) {
    const query = event.target.value.trim()
    
    if (this.searchTimeout) clearTimeout(this.searchTimeout)
    
    if (query.length < 2) {
      this.searchResultsTarget.innerHTML = ""
      this.searchResultsTarget.classList.add("hidden")
      return
    }

    this.searchTimeout = setTimeout(() => {
      fetch(`${this.urlValue}/search?query=${encodeURIComponent(query)}`)
        .then(response => response.json())
        .then(tickets => {
          this.renderSearchResults(tickets)
        })
        .catch(err => console.error("Search error:", err))
    }, 300)
  }

  renderSearchResults(tickets) {
    const container = this.searchResultsTarget
    container.classList.remove("hidden")
    
    if (tickets.length === 0) {
      container.innerHTML = `<p class="text-xs text-muted text-center p-3">No se encontraron asistentes</p>`
      return
    }

    container.innerHTML = tickets.map(ticket => {
      const isUsed = ticket.status === "used"
      const buttonText = isUsed ? "Ingresado" : "Registrar"
      const buttonClass = isUsed 
        ? "bg-surface-tertiary text-body-tertiary cursor-not-allowed border border-border"
        : "bg-primary text-white hover:bg-primary-hover active:scale-[0.95]"

      return `
        <div class="flex items-center justify-between p-3 border-b border-border-light last:border-0 hover:bg-surface-secondary transition-colors">
          <div class="text-left">
            <p class="text-sm font-bold text-heading">${ticket.attendee_name}</p>
            <p class="text-[10px] text-muted font-mono">${ticket.qr_code.substring(0, 8)}...</p>
          </div>
          <button type="button" 
                  data-action="click->check-in-scanner#checkInFromSearch"
                  data-check-in-scanner-qr-param="${ticket.qr_code}"
                  ${isUsed ? "disabled" : ""}
                  class="px-3.5 py-1.5 text-xs font-bold rounded-input transition-all ${buttonClass}">
            ${buttonText}
          </button>
        </div>
      `
    }).join("")
  }

  checkInFromSearch(event) {
    const qrCode = event.params.qr
    if (!qrCode) return
    this.processQR(qrCode)
    
    // Clear search input and results after a delay
    setTimeout(() => {
      this.manualInputTarget.value = ""
      this.searchResultsTarget.innerHTML = ""
      this.searchResultsTarget.classList.add("hidden")
    }, 1500)
  }
}
