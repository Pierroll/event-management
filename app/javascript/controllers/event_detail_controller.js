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

    L.marker(coords).addTo(this.mapInstance)

    // Force map to recalculate container bounds
    setTimeout(() => {
      if (this.mapInstance) {
        this.mapInstance.invalidateSize()
      }
    }, 200)
  }

  toggleFullscreen(event) {
    if (event) event.preventDefault()

    if (!this.hasMapContainerTarget) return

    const container = this.mapContainerTarget
    const isFullscreen = container.classList.contains("fixed")

    if (isFullscreen) {
      // Exit fullscreen
      container.className = "relative w-full h-[300px] rounded-2xl border border-border overflow-hidden shadow-sm"
      if (this.hasFullscreenIconTarget) {
        this.fullscreenIconTarget.setAttribute("d", "M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4")
      }
      document.body.style.overflow = ""
    } else {
      // Enter fullscreen
      container.className = "fixed inset-0 z-[250] w-screen h-screen bg-gray-950/90 backdrop-blur-md p-4 sm:p-10 flex items-center justify-center"
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