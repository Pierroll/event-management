import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reader", "manualInput", "result", "statsUsed", "statsTotal", "searchResults"]
  static values = { url: String }

  connect() {
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
      this.showResult(payload)
    })
    .catch(err => {
      console.error("Fetch error:", err)
      this.showResult({ success: false, error: 'Error de conexión' })
    })
  }

  showResult(payload) {
    this.resultTarget.classList.remove('hidden')
    this.resultTarget.classList.remove('bg-success/5', 'border-success/30', 'bg-error/10', 'border-error/30')

    const bodyEl = document.body

    if (payload.success) {
      this.resultTarget.classList.add('bg-success/5', 'border', 'border-success/30')
      this.resultTarget.innerHTML = `
        <p class="text-success font-semibold text-lg">✅ Ingreso registrado</p>
        <p class="text-success text-sm mt-1">${payload.attendee_name || 'Asistente registrado'}</p>
      `

      if (payload.stats) {
        if (this.hasStatsUsedTarget) this.statsUsedTarget.textContent = payload.stats.used
        if (this.hasStatsTotalTarget) this.statsTotalTarget.textContent = payload.stats.total
      }

      // Flash green background
      bodyEl.classList.add('flash-success')
      setTimeout(() => bodyEl.classList.remove('flash-success'), 800)

    } else {
      this.resultTarget.classList.add('bg-error/10', 'border', 'border-error/30')
      this.resultTarget.innerHTML = `<p class="text-error font-semibold">❌ ${payload.error || 'Error'}</p>`

      // Flash red background
      bodyEl.classList.add('flash-error')
      setTimeout(() => bodyEl.classList.remove('flash-error'), 800)
    }

    // Auto-resume scanner after 2 seconds
    setTimeout(() => {
      this.resultTarget.classList.add('hidden')
      if (this.scanner && typeof this.scanner.resume === 'function') {
        try {
          this.scanner.resume()
        } catch(e) {
          console.warn("Could not resume scanner state:", e)
        }
      }
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
