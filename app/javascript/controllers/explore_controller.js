import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="explore"
// Handles event search, filters, Leaflet map, and geolocation
export default class extends Controller {
  static targets = [
    "form", "resultsGrid", "mapContainer",
    "searchInput", "viewToggle",

    // Hidden inputs for rails backend
    "startDateInput", "endDateInput", "priceMinInput", "priceMaxInput",

    // Custom date options
    "customDateContainer", "customStart", "customEnd",

    // Custom price options
    "customPriceContainer", "customPriceMin", "customPriceMax"
  ]

  static values = {
    debounceMs: { type: Number, default: 400 }
  }

  connect() {
    this.mapInstance = null
    this.markersGroup = null
    this.debounceTimer = null

    // Automatically initialize Leaflet map on desktop if container exists and is visible
    if (window.innerWidth >= 1024 && this.hasMapContainerTarget) {
      // Small timeout to ensure DOM is fully rendered
      setTimeout(() => this.initMap(), 150)
    }
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

  // Toggle between list and map view (on mobile/tablet)
  toggleView(event) {
    const mode = event.params.mode || "list"
    const mapContainer = this.hasMapContainerTarget ? this.mapContainerTarget : null
    const resultsGrid = this.hasResultsGridTarget ? this.resultsGridTarget : null

    if (mode === "map" && mapContainer) {
      // Find the parent column containing the map on mobile and show it
      const mapWrapper = mapContainer.closest('.hidden.lg\\:block') || mapContainer
      mapWrapper.classList.remove("hidden")
      if (resultsGrid) resultsGrid.classList.add("hidden")
      this.initMap()
    } else {
      const mapWrapper = mapContainer ? (mapContainer.closest('.hidden.lg\\:block') || mapContainer) : null
      if (mapWrapper && window.innerWidth < 1024) mapWrapper.classList.add("hidden")
      if (resultsGrid) resultsGrid.classList.remove("hidden")
    }

    // Update active button styles
    this.viewToggleTargets.forEach(btn => {
      btn.classList.remove("bg-white", "text-heading", "shadow-raised")
      btn.classList.add("text-body-secondary")
    })
    event.currentTarget.classList.remove("text-body-secondary")
    event.currentTarget.classList.add("bg-white", "text-heading", "shadow-raised")
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

    if (!this.hasMapContainerTarget) return

    const defaultCoords = [-12.046374, -77.042793] // Lima, Peru
    const cityCoords = {
      "lima": [-12.046374, -77.042793],
      "cusco": [-13.5319, -71.9675],
      "arequipa": [-16.4090, -71.5375],
      "trujillo": [-8.1160, -79.0300],
      "chiclayo": [-6.7714, -79.8442]
    }

    const activeCityRadio = this.element.querySelector('input[name="city"]:checked')
    const activeCity = activeCityRadio ? activeCityRadio.value.toLowerCase().trim() : "all"
    
    let centerCoords = defaultCoords
    if (cityCoords[activeCity]) {
      centerCoords = cityCoords[activeCity]
    }

    this.mapInstance = L.map(this.mapContainerTarget).setView(centerCoords, 13)

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

    // Clear existing markers
    this.markersGroup.clearLayers()

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

    if (bounds.length > 1) {
      this.mapInstance.fitBounds(bounds, { padding: [30, 30] })
    } else if (bounds.length === 1) {
      this.mapInstance.setView(bounds[0], 14)
    } else {
      // Center on selected city if no markers
      const cityCoords = {
        "lima": [-12.046374, -77.042793],
        "cusco": [-13.5319, -71.9675],
        "arequipa": [-16.4090, -71.5375],
        "trujillo": [-8.1160, -79.0300],
        "chiclayo": [-6.7714, -79.8442]
      }
      const activeCityRadio = this.element.querySelector('input[name="city"]:checked')
      const activeCity = activeCityRadio ? activeCityRadio.value.toLowerCase().trim() : "all"
      if (cityCoords[activeCity]) {
        this.mapInstance.setView(cityCoords[activeCity], 13)
      }
    }
  }

  // Date Option Radio handler
  dateOptionChanged(event) {
    const option = event.target.value
    const today = new Date()
    
    // Toggle custom container
    if (this.hasCustomDateContainerTarget) {
      if (option === "custom") {
        this.customDateContainerTarget.classList.remove("hidden")
      } else {
        this.customDateContainerTarget.classList.add("hidden")
      }
    }

    if (this.hasStartDateInputTarget && this.hasEndDateInputTarget) {
      if (option === "all") {
        this.startDateInputTarget.value = ""
        this.endDateInputTarget.value = ""
        this.submitForm()
      } else if (option === "today") {
        const formatted = this.formatDate(today)
        this.startDateInputTarget.value = formatted
        this.endDateInputTarget.value = formatted
        this.submitForm()
      } else if (option === "tomorrow") {
        const tomorrow = new Date()
        tomorrow.setDate(today.getDate() + 1)
        const formatted = this.formatDate(tomorrow)
        this.startDateInputTarget.value = formatted
        this.endDateInputTarget.value = formatted
        this.submitForm()
      } else if (option === "weekend") {
        const nextFriday = new Date()
        const currentDay = today.getDay()
        const daysToFriday = (5 - currentDay + 7) % 7
        nextFriday.setDate(today.getDate() + daysToFriday)
        
        const nextSunday = new Date()
        nextSunday.setDate(nextFriday.getDate() + 2)

        this.startDateInputTarget.value = this.formatDate(nextFriday)
        this.endDateInputTarget.value = this.formatDate(nextSunday)
        this.submitForm()
      }
    }
  }

  // Custom date range inputs handler
  customDateChanged() {
    if (this.hasCustomStartTarget && this.hasCustomEndTarget && 
        this.hasStartDateInputTarget && this.hasEndDateInputTarget) {
      this.startDateInputTarget.value = this.customStartTarget.value
      this.endDateInputTarget.value = this.customEndTarget.value
      this.submitForm()
    }
  }

  // Price Option Radio handler
  priceOptionChanged(event) {
    const option = event.target.value

    if (this.hasCustomPriceContainerTarget) {
      if (option === "custom") {
        this.customPriceContainerTarget.classList.remove("hidden")
      } else {
        this.customPriceContainerTarget.classList.add("hidden")
      }
    }

    if (this.hasPriceMinInputTarget && this.hasPriceMaxInputTarget) {
      if (option === "all") {
        this.priceMinInputTarget.value = ""
        this.priceMaxInputTarget.value = ""
        this.submitForm()
      } else if (option === "free") {
        this.priceMinInputTarget.value = ""
        this.priceMaxInputTarget.value = "0"
        this.submitForm()
      } else if (option === "paid") {
        this.priceMinInputTarget.value = "0.01"
        this.priceMaxInputTarget.value = ""
        this.submitForm()
      }
    }
  }

  // Custom price range inputs handler with debounce
  customPriceChanged() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      if (this.hasCustomPriceMinTarget && this.hasCustomPriceMaxTarget && 
          this.hasPriceMinInputTarget && this.hasPriceMaxInputTarget) {
        this.priceMinInputTarget.value = this.customPriceMinTarget.value
        this.priceMaxInputTarget.value = this.customPriceMaxTarget.value
        this.submitForm()
      }
    }, this.debounceMsValue)
  }

  // Format date helper (YYYY-MM-DD)
  formatDate(date) {
    const yyyy = date.getFullYear()
    const mm = String(date.getMonth() + 1).padStart(2, '0')
    const dd = String(date.getDate()).padStart(2, '0')
    return `${yyyy}-${mm}-${dd}`
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