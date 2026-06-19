import { Controller } from "@hotwired/stimulus"

// Manages dynamic add/remove of nested ticket type rows
export default class extends Controller {
  static targets = ["template", "rows"]

  add() {
    const content = this.templateTarget.innerHTML.replaceAll("__INDEX__", new Date().getTime())
    this.rowsTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    const row = event.target.closest("[data-ticket-types-target='row']")
    const destroyCheckbox = row.querySelector("input[name*='[_destroy]']")
    if (destroyCheckbox) {
      destroyCheckbox.checked = true
      row.hidden = true
    } else {
      row.remove()
    }
  }
}
