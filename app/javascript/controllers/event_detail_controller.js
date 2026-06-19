import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-detail"
// Handles star rating UI, map rendering, and comment interactions
export default class extends Controller {
  static targets = ["starsContainer", "ratingInput", "commentForm"]

  connect() {
    this.setupStars()
    this.setupMap()
  }

  disconnect() {
    if (this.mapInstance) {
      this.mapInstance.remove()
      this.mapInstance = null
    }
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

    this.mapInstance = L.map(this.element).setView(coords, 15)

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