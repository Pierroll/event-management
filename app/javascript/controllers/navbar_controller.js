import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = ["menu", "dropdown"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  toggleDropdown(event) {
    event.preventDefault()
    this.dropdownTarget.classList.toggle("hidden")
    
    // Close when clicking outside
    const closeDropdown = (e) => {
      if (!this.element.contains(e.target)) {
        this.dropdownTarget.classList.add("hidden")
        document.removeEventListener("click", closeDropdown)
      }
    }
    
    if (!this.dropdownTarget.classList.contains("hidden")) {
      document.addEventListener("click", closeDropdown)
    }
  }

  // Handle ESC key to close
  closeOnEsc(event) {
    if (event.key === "Escape") {
      this.dropdownTarget.classList.add("hidden")
      if (this.hasMenuTarget) this.menuTarget.classList.add("hidden")
    }
  }
}
