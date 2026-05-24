import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-detail"
// Handles star rating UI and comment interactions
export default class extends Controller {
  static targets = ["starsContainer", "ratingInput", "commentForm"]

  connect() {
    this.setupStars()
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
        star.classList.remove("text-gray-300")
        star.classList.add("text-yellow-400")
      } else {
        star.classList.remove("text-yellow-400")
        star.classList.add("text-gray-300")
      }
    })
  }
}