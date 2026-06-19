import { Controller } from "@hotwired/stimulus"

// Countdown timer that shows remaining time until expires_at
export default class extends Controller {
  static targets = ["display"]
  static values = { expiresAt: String }

  connect() {
    this.expiresAtDate = new Date(this.expiresAtValue)
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  tick() {
    const now = new Date()
    const diff = this.expiresAtDate.getTime() - now.getTime()

    if (diff <= 0) {
      this.displayTarget.textContent = "00:00"
      this.displayTarget.closest("[data-controller]").classList.replace("bg-yellow-50", "bg-red-50")
      this.displayTarget.closest("[data-controller]").classList.replace("border-yellow-200", "border-red-200")
      this.displayTarget.classList.replace("text-yellow-800", "text-red-800")
      clearInterval(this.interval)
      return
    }

    const minutes = Math.floor(diff / 60000)
    const seconds = Math.floor((diff % 60000) / 1000)
    this.displayTarget.textContent = `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
  }
}
