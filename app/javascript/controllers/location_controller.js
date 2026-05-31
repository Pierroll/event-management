import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="location"
export default class extends Controller {
  static targets = ["dropdown", "mobileDropdown", "currentCityLabel", "mobileCityLabel"]

  connect() {
    this.cookieName = "selected_city"
    const savedCity = this.getCookie(this.cookieName)

    if (!savedCity) {
      this.detectSilently()
    }
  }

  // Detect location by IP using a public API
  async detectSilently() {
    try {
      const response = await fetch("https://ipapi.co/json/")
      if (!response.ok) throw new Error("ipapi fetch failed")
      
      const data = await response.json()
      if (data && data.city) {
        this.setCookie(this.cookieName, data.city)
        this.showToast(`Ubicación detectada: ${data.city}`, "success")
        
        // Reload page to apply changes if on relevant pages
        setTimeout(() => {
          window.location.reload()
        }, 1000)
      }
    } catch (error) {
      console.warn("[Location] ipapi failed, trying ip-api.com:", error)
      this.detectFallback()
    }
  }

  async detectFallback() {
    try {
      const response = await fetch("http://ip-api.com/json/")
      if (!response.ok) throw new Error("ip-api fetch failed")
      
      const data = await response.json()
      if (data && data.city) {
        this.setCookie(this.cookieName, data.city)
        this.showToast(`Ubicación detectada: ${data.city}`, "success")
        
        setTimeout(() => {
          window.location.reload()
        }, 1000)
      }
    } catch (error) {
      console.error("[Location] Geolocation autodetection failed completely:", error)
    }
  }

  // Force location detection manually from UI button
  async forceDetect(event) {
    event.preventDefault()
    this.showToast("Detectando ubicación...", "info")
    
    // Check if navigator geolocation is available and preferred
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          try {
            const { latitude, longitude } = position.coords
            // Reverse geocode using OpenStreetMap Nominatim
            const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`)
            const data = await response.json()
            
            // Get city/town/village name
            const city = data.address.city || data.address.town || data.address.village || data.address.state
            if (city) {
              this.setCookie(this.cookieName, city)
              this.showToast(`Ubicación exacta detectada: ${city}`, "success")
              this.redirectWithCity(city)
            } else {
              this.detectSilently()
            }
          } catch (e) {
            this.detectSilently()
          }
        },
        () => {
          // Fallback to IP if navigator geolocation permission is denied or fails
          this.detectSilently()
        }
      )
    } else {
      this.detectSilently()
    }
  }

  // Select city manually from dropdown
  select(event) {
    event.preventDefault()
    const city = event.params.city
    this.setCookie(this.cookieName, city)
    this.redirectWithCity(city)
  }

  // Redirect or reload with selected city
  redirectWithCity(city) {
    const targetUrl = `/events?city=${encodeURIComponent(city)}`
    
    // If we are already on the events index page, we can let Turbo handle it or force load
    if (window.location.pathname === "/events") {
      window.location.href = targetUrl
    } else {
      window.location.href = targetUrl
    }
  }

  // Toggle Dropdowns (Desktop & Mobile)
  toggleDropdown(event) {
    event.preventDefault()
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle("hidden")
    }
  }

  // Close dropdown if clicked outside
  close(event) {
    if (this.hasDropdownTarget && !this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  // Cookie Helpers
  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return decodeURIComponent(parts.pop().split(";").shift())
    return null
  }

  setCookie(name, value, days = 365) {
    const date = new Date()
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
    const expires = `; expires=${date.toUTCString()}`
    document.cookie = `${name}=${encodeURIComponent(value || "")}${expires}; path=/`
  }

  showToast(message, type = "info") {
    const event = new CustomEvent("sge:toast", { detail: { message, type } })
    window.dispatchEvent(event)
  }
}
