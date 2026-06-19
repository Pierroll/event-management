import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="explore"
// Handles event search, filters, Leaflet map, and geolocation
export default class extends Controller {
  static targets = [
    "form", "resultsGrid", "mapContainer",
    "searchInput", "categorySelect", "cityInput",
    "dateStart", "dateEnd", "priceMin", "priceMax",
    "viewToggle"
  ]

  static values = {
    debounceMs: { type: Number, default: 400 }
  }

  connect() {
    this.mapInstance = null
    this.markersGroup = null
    this.debounceTimer = null
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
    if (this.mapInstance) {
      this.mapInstance.remove()
      this.mapInstance = null
    }
  }

  // Handle text search with debounce
  search(event) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.submitForm()
    }, this.debounceMsValue)
  }

  // Handle filter change (category, city, dates, price)
  filterChange(event) {
    this.submitForm()
  }

  // Handle proximity/geolocation search
  activateProximity(event) {
    if (!navigator.geolocation) {
      this.showToast("La geolocalización no está soportada por tu navegador.", "warning")
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const latInput = this.element.querySelector('input[name="latitude"]') || this.createHiddenInput("latitude")
        const lngInput = this.element.querySelector('input[name="longitude"]') || this.createHiddenInput("longitude")
        const radiusInput = this.element.querySelector('input[name="radius"]') || this.createHiddenInput("radius")

        latInput.value = position.coords.latitude
        lngInput.value = position.coords.longitude
        radiusInput.value = 10 // Default 10km radius

        // Center map if initialized
        if (this.mapInstance) {
          this.mapInstance.setView([position.coords.latitude, position.coords.longitude], 13)
        }

        this.showToast("Buscando eventos en un radio de 10 km.", "success")
        this.submitForm()
      },
      (error) => {
        console.error("[Explore] Geolocation failed:", error)
        this.showToast("No pudimos acceder a tu ubicación. Verifica tus permisos.", "error")
      }
    )
  }

  // Toggle between list and map view
  toggleView(event) {
    const mode = event.params.mode || "list"
    const mapContainer = this.hasMapContainerTarget ? this.mapContainerTarget : null
    const resultsGrid = this.hasResultsGridTarget ? this.resultsGridTarget : null

    if (mode === "map" && mapContainer) {
      mapContainer.classList.remove("hidden")
      if (resultsGrid) resultsGrid.classList.add("hidden")
      this.initMap()
    } else {
      if (mapContainer) mapContainer.classList.add("hidden")
      if (resultsGrid) resultsGrid.classList.remove("hidden")
    }

    // Update active button styles
    this.viewToggleTargets.forEach(btn => {
      btn.classList.remove("bg-brand-primary", "text-white")
      btn.classList.add("bg-surface-secondary", "text-body-secondary")
    })
    event.currentTarget.classList.remove("bg-surface-secondary", "text-body-secondary")
    event.currentTarget.classList.add("bg-brand-primary", "text-white")
  }

  // Initialize Leaflet map
  initMap() {
    if (this.mapInstance) {
      setTimeout(() => this.mapInstance.invalidateSize(), 100)
      return
    }

    if (typeof L === "undefined") {
      console.warn("[Explore] Leaflet L is not loaded.")
      return
    }

    const defaultCoords = [-12.046374, -77.042793] // Lima, Peru

    this.mapInstance = L.map(this.mapContainerTarget).setView(defaultCoords, 13)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.mapInstance)

    this.markersGroup = L.layerGroup().addTo(this.mapInstance)

    // Load markers from existing event data
    this.loadMapMarkers()
  }

  // Load markers from data attributes on event cards
  loadMapMarkers() {
    if (!this.markersGroup || !this.mapInstance) return

    const eventCards = this.element.querySelectorAll("[data-event-lat][data-event-lng]")
    const bounds = []

    eventCards.forEach(card => {
      const lat = parseFloat(card.dataset.eventLat)
      const lng = parseFloat(card.dataset.eventLng)
      if (isNaN(lat) || isNaN(lng)) return

      const coords = [lat, lng]
      bounds.push(coords)

      const name = card.dataset.eventName || "Evento"
      const city = card.dataset.eventCity || ""
      const price = card.dataset.eventPrice || "0"
      const eventId = card.dataset.eventId || ""
      const date = card.dataset.eventDate || ""

      const marker = L.marker(coords)
      const popupContent = `
        <div class="p-2 select-none">
          <h4 class="font-semibold text-heading">${name}</h4>
          <p class="text-xs text-body-tertiary my-1">${city} | ${date}</p>
          <div class="flex items-center justify-between mt-2">
            <span class="text-xs font-bold text-link">${parseFloat(price) > 0 ? `S/${price}` : "Gratis"}</span>
            <a href="/events/${eventId}" class="text-xs font-medium text-link hover:underline">Ver detalle →</a>
          </div>
        </div>
      `
      marker.bindPopup(popupContent).addTo(this.markersGroup)
    })

    if (bounds.length > 0) {
      this.mapInstance.fitBounds(bounds, { padding: [30, 30] })
    }
  }

  submitForm() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  createHiddenInput(name) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    this.formTarget.appendChild(input)
    return input
  }

  showToast(message, type = "info") {
    const event = new CustomEvent("sge:toast", { detail: { message, type } })
    window.dispatchEvent(event)
  }
}