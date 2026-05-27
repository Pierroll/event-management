import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
// Handles interactive image carousels with smooth transitions
export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.showSlide(this.indexValue)
  }

  next() {
    let nextIndex = this.indexValue + 1
    if (nextIndex >= this.slideTargets.length) {
      nextIndex = 0
    }
    this.indexValue = nextIndex
  }

  prev() {
    let prevIndex = this.indexValue - 1
    if (prevIndex < 0) {
      prevIndex = this.slideTargets.length - 1
    }
    this.indexValue = prevIndex
  }

  jump(event) {
    const index = parseInt(event.currentTarget.dataset.index) || 0
    this.indexValue = index
  }

  indexValueChanged(value, oldValue) {
    this.showSlide(value)
  }

  showSlide(index) {
    if (this.slideTargets.length === 0) return

    // Hide all slides, show active slide
    this.slideTargets.forEach((slide, i) => {
      const isActive = i === index
      slide.classList.toggle("opacity-100", isActive)
      slide.classList.toggle("z-10", isActive)
      slide.classList.toggle("opacity-0", !isActive)
      slide.classList.toggle("pointer-events-none", !isActive)
    })

    // Update dots indicator active classes
    if (this.hasDotTargets) {
      this.dotTargets.forEach((dot, i) => {
        const isActive = i === index
        if (isActive) {
          dot.classList.add("bg-white")
          dot.classList.remove("bg-white/50")
        } else {
          dot.classList.remove("bg-white")
          dot.classList.add("bg-white/50")
        }
      })
    }
  }
}
