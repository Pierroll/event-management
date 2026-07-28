import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["activeTab", "inactiveTab", "activePanel", "inactivePanel"]

  connect() {
    if (this.tabTargets.length > 0) {
      this.showTab(this.tabTargets[0].dataset.tabId)
    }
  }

  select(event) {
    event.preventDefault()
    this.showTab(event.currentTarget.dataset.tabId)
  }

  showTab(tabId) {
    // Read directly from DOM to avoid any Stimulus version bugs with static classes
    const activeTab = (this.element.dataset.ecosystemTabsActiveTabClass || "").split(" ").filter(Boolean)
    const inactiveTab = (this.element.dataset.ecosystemTabsInactiveTabClass || "").split(" ").filter(Boolean)
    const activePanel = (this.element.dataset.ecosystemTabsActivePanelClass || "").split(" ").filter(Boolean)
    const inactivePanel = (this.element.dataset.ecosystemTabsInactivePanelClass || "").split(" ").filter(Boolean)

    this.tabTargets.forEach((tab) => {
      if (tab.dataset.tabId === tabId) {
        if (activeTab.length) tab.classList.add(...activeTab)
        if (inactiveTab.length) tab.classList.remove(...inactiveTab)
      } else {
        if (activeTab.length) tab.classList.remove(...activeTab)
        if (inactiveTab.length) tab.classList.add(...inactiveTab)
      }
    })

    this.panelTargets.forEach((panel) => {
      if (panel.dataset.tabId === tabId) {
        if (inactivePanel.length) panel.classList.remove(...inactivePanel)
        if (activePanel.length) panel.classList.add(...activePanel)
      } else {
        if (activePanel.length) panel.classList.remove(...activePanel)
        if (inactivePanel.length) panel.classList.add(...inactivePanel)
      }
    })
  }
}
