import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-detail"
// Handles star rating UI, map rendering, and comment interactions
export default class extends Controller {
  static targets = ["starsContainer", "ratingInput", "commentForm", "mapContainer", "fullscreenIcon", "mapElement"]

  connect() {
    this.setupStars()
    this.setupMap()
    this.escHandler = (e) => {
      if (e.key === "Escape" && this.hasMapContainerTarget && this.mapContainerTarget.classList.contains("fixed")) {
        this.toggleFullscreen(e)
      }
    }
    window.addEventListener("keydown", this.escHandler)
  }

  disconnect() {
    if (this.mapInstance) {
      this.mapInstance.remove()
      this.mapInstance = null
    }
    window.removeEventListener("keydown", this.escHandler)
  }

  setupMap() {
    const latAttr = this.element.dataset.lat
    const lngAttr = this.element.dataset.lng
    if (!latAttr || !lngAttr) return

    const lat = parseFloat(latAttr)
    const lng = parseFloat(lngAttr)
    if (isNaN(lat) || isNaN(lng)) return

    if (typeof L === "undefined") {
      console.warn("[EventDetail] Leaflet L is not loaded.")
      return
    }

    const coords = [lat, lng]

    // Avoid double initialization
    if (this.mapInstance) return

    const mapElement = this.hasMapElementTarget ? this.mapElementTarget : this.element
    this.mapInstance = L.map(mapElement).setView(coords, 15)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.mapInstance)

    // Grupos para controlar capas
    this.eventLayer = L.featureGroup().addTo(this.mapInstance)
    this.hotelsLayer = L.featureGroup()
    this.restaurantsLayer = L.featureGroup()
    this.markers = {} // Almacena marcadores para interacciones de hover

    // Pin principal del evento (Rojo)
    const eventIcon = L.divIcon({ html: '<div class="bg-red-600 text-white rounded-full w-9 h-9 flex items-center justify-center shadow-lg border-[3px] border-white text-base">📍</div>', className: '', iconSize: [36, 36], iconAnchor: [18, 18] })
    const eventMarker = L.marker(coords, { icon: eventIcon }).bindPopup(`
      <div class="text-center min-w-[120px]">
        <p class="text-[10px] uppercase font-bold text-red-500 tracking-wider mb-1">Sede Central</p>
        <b class="text-gray-900 text-sm block">El Evento</b>
      </div>
    `)
    this.eventLayer.addLayer(eventMarker)

    // Pines de Restaurantes (Naranjas)
    const restaurantsRaw = this.element.dataset.restaurants
    if (restaurantsRaw) {
      try {
        const foodIcon = L.divIcon({ html: '<div class="bg-orange-500 text-white rounded-full w-8 h-8 flex items-center justify-center shadow-lg border-2 border-white text-sm">🍽️</div>', className: '', iconSize: [32, 32], iconAnchor: [16, 16] })
        const restaurants = JSON.parse(restaurantsRaw)
        restaurants.forEach((r, index) => {
          if (r.latitude && r.longitude) {
            const url = `https://restaurants-seven-tan.vercel.app/restaurants/${r.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`
            const popupHtml = `
              <div class="min-w-[150px]">
                <p class="text-[9px] uppercase font-bold text-orange-500 tracking-wider mb-0.5">Restaurante</p>
                <b class="text-gray-900 text-sm block mb-1 leading-tight">${r.name}</b>
                <div class="flex items-center gap-1 mb-2 text-xs text-gray-600 font-medium">
                  <span class="text-yellow-500">★</span> ${r.avgRating || 'Nuevo'}
                </div>
                <a href="${url}" target="_blank" class="block w-full text-center bg-orange-50 hover:bg-orange-100 text-orange-600 font-bold text-[10px] uppercase py-1.5 rounded-lg transition-colors border border-orange-100">Visitar RestoPoint</a>
              </div>
            `
            const m = L.marker([parseFloat(r.latitude), parseFloat(r.longitude)], { icon: foodIcon }).bindPopup(popupHtml)
            this.restaurantsLayer.addLayer(m)
            this.markers[`restaurant-${index}`] = m
          }
        })
      } catch (e) {
        console.error("Error parsing restaurants JSON", e)
      }
    }

    // Pines de Hoteles (Azules) - Preparado para cuando Hospy envíe coordenadas
    const hotelsRaw = this.element.dataset.hotels
    if (hotelsRaw) {
      try {
        const hotelIcon = L.divIcon({ html: '<div class="bg-indigo-600 text-white rounded-full w-8 h-8 flex items-center justify-center shadow-lg border-2 border-white text-sm">🏨</div>', className: '', iconSize: [32, 32], iconAnchor: [16, 16] })
        const hotels = JSON.parse(hotelsRaw)
        
        // Setup dates for URL if data-event-start exists (mocking it here since we can't pass erb directly into JS without dataset, but we can just fallback)
        hotels.forEach((h, index) => {
          if (h.latitude && h.longitude) {
            const url = `https://hospy.pages.dev/hospedajes/${h.id}`
            const popupHtml = `
              <div class="min-w-[150px]">
                <p class="text-[9px] uppercase font-bold text-indigo-500 tracking-wider mb-0.5">${h.type ? h.type.replace('_', ' ') : 'Hospedaje'}</p>
                <b class="text-gray-900 text-sm block mb-1 leading-tight">${h.name}</b>
                <div class="flex items-center justify-between mb-2">
                  <span class="text-xs text-gray-600 font-medium"><span class="text-yellow-500">★</span> ${h.average_rating || 'Nuevo'}</span>
                  ${h.precio_desde ? `<span class="text-indigo-600 font-bold text-xs">S/ ${h.precio_desde}</span>` : ''}
                </div>
                <a href="${url}" target="_blank" class="block w-full text-center bg-indigo-50 hover:bg-indigo-100 text-indigo-600 font-bold text-[10px] uppercase py-1.5 rounded-lg transition-colors border border-indigo-100">Visitar Hospy</a>
              </div>
            `
            const m = L.marker([parseFloat(h.latitude), parseFloat(h.longitude)], { icon: hotelIcon }).bindPopup(popupHtml)
            this.hotelsLayer.addLayer(m)
            this.markers[`hotel-${index}`] = m
          }
        })
      } catch (e) {
        console.error("Error parsing hotels JSON", e)
      }
    }

    // Force map to recalculate container bounds and set view to event
    setTimeout(() => {
      if (this.mapInstance) {
        this.mapInstance.invalidateSize()
        this.mapInstance.setView(coords, 15)
      }
    }, 200)
  }

  toggleHotels(e) {
    if (!this.mapInstance) return
    if (this.mapInstance.hasLayer(this.hotelsLayer)) {
      this.mapInstance.removeLayer(this.hotelsLayer)
      e.currentTarget.classList.add('opacity-50')
      e.currentTarget.classList.remove('bg-indigo-50')
    } else {
      this.mapInstance.addLayer(this.hotelsLayer)
      e.currentTarget.classList.remove('opacity-50')
      e.currentTarget.classList.add('bg-indigo-50')
      const lat = parseFloat(this.element.dataset.lat)
      const lng = parseFloat(this.element.dataset.lng)
      if (this.hotelsLayer.getLayers().length > 0) {
        this.mapInstance.fitBounds(this.hotelsLayer.getBounds().extend(L.latLng(lat, lng)).pad(0.1))
      }
    }
  }

  toggleRestaurants(e) {
    if (!this.mapInstance) return
    if (this.mapInstance.hasLayer(this.restaurantsLayer)) {
      this.mapInstance.removeLayer(this.restaurantsLayer)
      e.currentTarget.classList.add('opacity-50')
      e.currentTarget.classList.remove('bg-orange-50')
    } else {
      this.mapInstance.addLayer(this.restaurantsLayer)
      e.currentTarget.classList.remove('opacity-50')
      e.currentTarget.classList.add('bg-orange-50')
      const lat = parseFloat(this.element.dataset.lat)
      const lng = parseFloat(this.element.dataset.lng)
      if (this.restaurantsLayer.getLayers().length > 0) {
        this.mapInstance.fitBounds(this.restaurantsLayer.getBounds().extend(L.latLng(lat, lng)).pad(0.1))
      }
    }
  }

  highlightPin(e) {
    if (!this.mapInstance) return
    const id = e.currentTarget.dataset.markerId
    const marker = this.markers[id]
    if (marker) {
      marker.openPopup()
      // Center map gently to show user exactly where it is
      this.mapInstance.panTo(marker.getLatLng())
    }
  }

  resetPin(e) {
    if (!this.mapInstance) return
    const id = e.currentTarget.dataset.markerId
    const marker = this.markers[id]
    if (marker) {
      marker.closePopup()
    }
  }

  // Trazado de ruta geolocalizada
  showUserRoute() {
    if (!navigator.geolocation) {
      alert("Tu navegador no soporta geolocalización.")
      return
    }

    // Cambiar texto de botón para indicar carga (opcional, por UX)
    const btn = event.currentTarget
    const originalContent = btn.innerHTML
    btn.innerHTML = '<svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Ubicando...'

    navigator.geolocation.getCurrentPosition(
      (position) => {
        btn.innerHTML = originalContent
        if (!this.mapInstance) return
        
        const userLat = position.coords.latitude
        const userLng = position.coords.longitude
        const eventLat = parseFloat(this.element.dataset.lat)
        const eventLng = parseFloat(this.element.dataset.lng)

        // Custom marker para el usuario
        const userIcon = L.divIcon({ html: '<div class="bg-blue-600 text-white rounded-full w-8 h-8 flex items-center justify-center shadow-lg border-2 border-white text-xs font-bold">Tú</div>', className: '', iconSize: [32, 32], iconAnchor: [16, 16] })
        
        L.marker([userLat, userLng], { icon: userIcon }).bindPopup('<b class="text-blue-600">Tu ubicación actual</b>').addTo(this.mapInstance)

        // Línea punteada hacia el evento
        const latlngs = [
          [userLat, userLng],
          [eventLat, eventLng]
        ]
        const polyline = L.polyline(latlngs, { color: '#2563EB', dashArray: '8, 8', weight: 3, opacity: 0.8 }).addTo(this.mapInstance)

        // Hacer zoom para que entren ambos puntos
        this.mapInstance.fitBounds(polyline.getBounds(), { padding: [50, 50], animate: true })
      },
      (error) => {
        btn.innerHTML = originalContent
        console.error("Geolocalización denegada o fallida", error)
        alert("No pudimos obtener tu ubicación. Por favor, asegúrate de permitir el acceso en tu navegador.")
      }
    )
  }

  toggleFullscreen(event) {
    if (event) event.preventDefault()

    if (!this.hasMapContainerTarget) return

    const container = this.mapContainerTarget
    const isFullscreen = container.classList.contains("fixed")

    if (isFullscreen) {
      // Exit fullscreen
      container.className = "relative w-full h-[300px] rounded-2xl border border-border overflow-hidden shadow-sm transition-all duration-300"
      if (this.hasFullscreenIconTarget) {
        this.fullscreenIconTarget.setAttribute("d", "M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4")
      }
      document.body.style.overflow = ""
    } else {
      // Enter fullscreen (Modal Style)
      container.className = "fixed inset-4 md:inset-12 z-[9999] bg-white rounded-3xl shadow-[0_0_0_9999px_rgba(0,0,0,0.8)] border border-border overflow-hidden transition-all duration-300"
      if (this.hasFullscreenIconTarget) {
        this.fullscreenIconTarget.setAttribute("d", "M6 18L18 6M6 6l12 12")
      }
      document.body.style.overflow = "hidden"
    }

    // Recalculate Leaflet bounds
    setTimeout(() => {
      if (this.mapInstance) {
        this.mapInstance.invalidateSize()
      }
    }, 100)
  }

  // Set up star rating from existing value
  setupStars() {
    const ratingInput = this.hasRatingInputTarget ? this.ratingInputTarget : null
    if (!ratingInput) return

    const currentValue = parseInt(ratingInput.value) || 0
    this.updateStarsDisplay(currentValue)

    // Listen to Turbo form submissions
    if (this.hasCommentFormTarget) {
      this.commentFormTarget.addEventListener("turbo:submit-end", (event) => {
        if (event.detail.success) {
          ratingInput.value = "0"
          this.updateStarsDisplay(0)
        }
      })
    }
  }


  // Click on a star to set rating
  rate(event) {
    const rating = parseInt(event.params.rating) || 0
    const ratingInput = this.hasRatingInputTarget ? this.ratingInputTarget : null

    if (ratingInput) {
      ratingInput.value = rating
    }

    this.updateStarsDisplay(rating)
  }

  // Hover effect on stars
  highlightStars(event) {
    const rating = parseInt(event.params.rating) || 0
    this.updateStarsDisplay(rating, true)
  }

  // Reset hover effect
  resetStars(event) {
    const ratingInput = this.hasRatingInputTarget ? this.ratingInputTarget : null
    const currentValue = parseInt(ratingInput?.value) || 0
    this.updateStarsDisplay(currentValue, false)
  }

  // Update the visual state of stars
  updateStarsDisplay(rating, isHover = false) {
    if (!this.hasStarsContainerTarget) return

    const stars = this.starsContainerTarget.querySelectorAll("[data-event-detail-target=\"star\"]")
    stars.forEach(star => {
      const starValue = parseInt(star.dataset.rating) || 0
      if (starValue <= rating) {
        star.classList.remove("text-muted")
        star.classList.add("text-yellow-400")
      } else {
        star.classList.remove("text-yellow-400")
        star.classList.add("text-muted")
      }
    })
  }
}