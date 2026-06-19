import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
// Handles interactive image carousels with smooth transitions and autoplay
export default class extends Controller {
  static targets = ["slide", "dot", "thumb"]
  static values = {
    index: { type: Number, default: 0 },
    autoplayInterval: { type: Number, default: 4000 }
  }

  connect() {
    console.log("[SGE Carousel] Connected. Slides found:", this.slideTargets.length, "Dots found:", this.dotTargets.length, "Thumbs found:", this.thumbTargets.length)
    this.showSlide(this.indexValue)
    this.startAutoplay()
  }

  disconnect() {
    this.stopAutoplay()
  }

  next() {
    this.resetAutoplay()
    let nextIndex = this.indexValue + 1
    if (nextIndex >= this.slideTargets.length) {
      nextIndex = 0
    }
    this.indexValue = nextIndex
  }

  prev() {
    this.resetAutoplay()
    let prevIndex = this.indexValue - 1
    if (prevIndex < 0) {
      prevIndex = this.slideTargets.length - 1
    }
    this.indexValue = prevIndex
  }

  jump(event) {
    this.resetAutoplay()
    const index = parseInt(event.currentTarget.dataset.index) || 0
    this.indexValue = index
  }

  startAutoplay() {
    if (this.slideTargets.length <= 1) return
    this.stopAutoplay() // Prevent multiple timers
    this.autoplayTimer = setInterval(() => {
      let nextIndex = this.indexValue + 1
      if (nextIndex >= this.slideTargets.length) {
        nextIndex = 0
      }
      this.indexValue = nextIndex
    }, this.autoplayIntervalValue)
  }

  stopAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer)
      this.autoplayTimer = null
    }
  }

  resetAutoplay() {
    this.stopAutoplay()
    this.startAutoplay()
  }

  indexValueChanged(value, oldValue) {
    this.showSlide(value)
  }

  showSlide(index) {
    if (this.slideTargets.length === 0) return
    console.log("[SGE Carousel] Displaying index:", index)

    // Hide all slides, show active slide
    this.slideTargets.forEach((slide, i) => {
      const isActive = i === index
      slide.style.opacity = isActive ? "1" : "0"
      slide.style.zIndex  = isActive ? "10" : "0"
      slide.style.pointerEvents = isActive ? "" : "none"
    })

    // Dots
    if (this.hasDotTargets) {
      this.dotTargets.forEach((dot, i) => {
        const isActive = i === index
        dot.style.opacity = isActive ? "1" : "0.4"
        dot.style.transform = isActive ? "scale(1.25)" : "scale(1)"
      })
    }

    // Thumbnails
    if (this.hasThumbTargets) {
      this.thumbTargets.forEach((thumb, i) => {
        if (i === index) {
          thumb.classList.remove("border-transparent", "opacity-60")
          thumb.classList.add("border-primary", "opacity-100")
        } else {
          thumb.classList.remove("border-primary", "opacity-100")
          thumb.classList.add("border-transparent", "opacity-60")
        }
      })
    }
  }
}
