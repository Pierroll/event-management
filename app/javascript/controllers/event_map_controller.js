import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-map"
export default class extends Controller {
  static targets = [
    "modal", "mapContainer", "searchInput", 
    "addressInput", "cityInput", "latInput", "lngInput"
  ]

  connect() {
    this.map = null
    this.marker = null
    this.tempLatLng = null
    this.tempAddress = null
    this.tempCity = null
  }

  // Open the interactive map modal
  openModal(event) {
    if (event) event.preventDefault()

    // Show modal
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.classList.add("flex")
    }

    // Initialize map
    this.initMap()
  }

  // Close the modal
  closeModal(event) {
    if (event) event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.classList.remove("flex")
    }
  }

  // Initialize Leaflet Map inside the modal container
  initMap() {
    const L = window.L
    if (typeof L === "undefined") {
      console.error("[EventMap] Leaflet L is not loaded globally.")
      this.showToast("No pudimos cargar la librería de mapas. Reintente en unos momentos.", "error")
      return
    }

    const currentLat = parseFloat(this.latInputTarget.value)
    const currentLng = parseFloat(this.lngInputTarget.value)
    
    const hasExistingCoords = !isNaN(currentLat) && !isNaN(currentLng)
    
    // If already initialized, just update view and size
    if (this.map) {
      if (hasExistingCoords) {
        const coords = [currentLat, currentLng]
        this.map.setView(coords, 15)
        this.marker.setLatLng(coords)
        this.tempLatLng = { lat: currentLat, lng: currentLng }
      }
      setTimeout(() => this.map.invalidateSize(), 100)
      return
    }

    // Default fallback: Lima, Peru
    const fallbackCoords = [-12.046374, -77.042793]
    const initialCoords = hasExistingCoords ? [currentLat, currentLng] : fallbackCoords

    // Initialize Map Instance
    this.map = L.map(this.mapContainerTarget).setView(initialCoords, hasExistingCoords ? 15 : 13)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    // Add Draggable Marker
    this.marker = L.marker(initialCoords, { draggable: true }).addTo(this.map)

    if (hasExistingCoords) {
      this.tempLatLng = { lat: currentLat, lng: currentLng }
      this.tempAddress = this.addressInputTarget.value
      this.tempCity = this.cityInputTarget.value
    }

    // Marker Drag Event
    this.marker.on("dragend", () => {
      const position = this.marker.getLatLng()
      this.updateTemporaryLocation(position.lat, position.lng)
    })

    // Map Click Event to reposition marker
    this.map.on("click", (e) => {
      this.marker.setLatLng(e.latlng)
      this.updateTemporaryLocation(e.latlng.lat, e.latlng.lng)
    })

    // If it's a new record with no coordinates, attempt to geolocalize to user's position
    if (!hasExistingCoords) {
      this.geolocalizeUser(L)
    }

    // Invalidate size once visible in the DOM
    setTimeout(() => this.map.invalidateSize(), 150)
  }

  // Geolocalize user to set initial map view to their current position
  geolocalizeUser(L) {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords
          const coords = [latitude, longitude]
          
          if (this.map && this.marker) {
            this.map.setView(coords, 15)
            this.marker.setLatLng(coords)
            this.updateTemporaryLocation(latitude, longitude)
          }
        },
        () => {
          // Fallback to IP geolocation if GPS fails/denied
          this.geolocalizeByIp(L)
        }
      )
    } else {
      this.geolocalizeByIp(L)
    }
  }

  // Fallback IP-based Geolocation
  async geolocalizeByIp(L) {
    try {
      const response = await fetch("https://ipapi.co/json/")
      if (!response.ok) throw new Error("IP fetch failed")
      
      const data = await response.json()
      if (data && data.latitude && data.longitude) {
        const coords = [data.latitude, data.longitude]
        if (this.map && this.marker) {
          this.map.setView(coords, 14)
          this.marker.setLatLng(coords)
          this.updateTemporaryLocation(data.latitude, data.longitude)
        }
      }
    } catch (e) {
      console.warn("[EventMap] IP geolocation failed:", e)
    }
  }

  // Reverse Geocoding via Nominatim OpenStreetMap API
  async updateTemporaryLocation(lat, lng) {
    this.tempLatLng = { lat, lng }
    
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`, {
        headers: {
          "Accept-Language": "es"
        }
      })
      if (!response.ok) throw new Error("reverse geocode fetch failed")
      
      const data = await response.json()
      if (data) {
        const addr = data.address
        
        // Extract road and house number
        const road = addr.road || addr.suburb || addr.neighbourhood || ""
        const houseNumber = addr.house_number || ""
        this.tempAddress = houseNumber ? `${road} ${houseNumber}` : road
        
        // Fallback for address
        if (!this.tempAddress && data.display_name) {
          this.tempAddress = data.display_name.split(",")[0] || ""
        }
        
        // Extract city/town/village
        this.tempCity = addr.city || addr.town || addr.village || addr.city_district || addr.state || ""
        
        this.showToast(`Dirección detectada: ${this.tempAddress}`, "success")
      }
    } catch (error) {
      console.error("[EventMap] Reverse geocoding failed:", error)
      this.showToast("Error al obtener la dirección del mapa. Las coordenadas se mantendrán.", "warning")
    }
  }

  // Search Address inside the map modal
  async searchAddress(event) {
    if (event) event.preventDefault()
    
    const query = this.searchInputTarget.value.trim()
    if (!query) return

    this.showToast("Buscando dirección...", "info")

    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1&addressdetails=1`, {
        headers: {
          "Accept-Language": "es"
        }
      })
      if (!response.ok) throw new Error("search fetch failed")

      const data = await response.json()
      if (data && data.length > 0) {
        const result = data[0]
        const lat = parseFloat(result.lat)
        const lng = parseFloat(result.lon)
        
        const coords = [lat, lng]
        this.map.setView(coords, 16)
        this.marker.setLatLng(coords)
        
        this.tempLatLng = { lat, lng }
        
        const addr = result.address
        const road = addr.road || addr.suburb || addr.neighbourhood || ""
        const houseNumber = addr.house_number || ""
        this.tempAddress = houseNumber ? `${road} ${houseNumber}` : road
        
        if (!this.tempAddress && result.display_name) {
          this.tempAddress = result.display_name.split(",")[0] || ""
        }

        this.tempCity = addr.city || addr.town || addr.village || addr.city_district || addr.state || ""
        
        this.showToast(`Ubicación encontrada: ${this.tempAddress}`, "success")
      } else {
        this.showToast("No pudimos encontrar esa dirección en el mapa.", "warning")
      }
    } catch (error) {
      console.error("[EventMap] Search failed:", error)
      this.showToast("Ocurrió un error al buscar la dirección.", "error")
    }
  }

  // Save selected coordinates & address into main form
  saveLocation(event) {
    if (event) event.preventDefault()

    if (this.tempLatLng) {
      this.latInputTarget.value = this.tempLatLng.lat.toFixed(8)
      this.lngInputTarget.value = this.tempLatLng.lng.toFixed(8)
      
      if (this.tempAddress) {
        this.addressInputTarget.value = this.tempAddress
      }
      
      if (this.tempCity) {
        this.cityInputTarget.value = this.tempCity
      }
      
      this.showToast("Ubicación guardada con éxito.", "success")
      this.closeModal()
    } else {
      this.showToast("Selecciona primero un punto en el mapa.", "warning")
    }
  }

  showToast(message, type = "info") {
    const event = new CustomEvent("sge:toast", { detail: { message, type } })
    window.dispatchEvent(event)
  }
}
