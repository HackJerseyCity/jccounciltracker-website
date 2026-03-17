import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { key: String, open: { type: Boolean, default: true } }

  connect() {
    const stored = localStorage.getItem(this.storageKey)
    if (stored !== null) {
      this.openValue = stored === "true"
    }
    this.render()
  }

  toggle() {
    this.openValue = !this.openValue
    localStorage.setItem(this.storageKey, this.openValue)
    this.render()
  }

  render() {
    this.contentTarget.classList.toggle("hidden", !this.openValue)
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = this.openValue ? "rotate(0deg)" : "rotate(-90deg)"
    }
  }

  get storageKey() {
    return `collapsible:${this.keyValue}`
  }
}
