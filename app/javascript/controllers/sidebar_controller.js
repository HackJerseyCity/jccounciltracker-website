import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "label", "main"]
  static values = { expanded: { type: Boolean, default: false } }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    if (this.expandedValue) {
      this.sidebarTarget.classList.remove("w-16")
      this.sidebarTarget.classList.add("w-56")
      this.labelTargets.forEach(el => el.classList.remove("hidden"))
    } else {
      this.sidebarTarget.classList.remove("w-56")
      this.sidebarTarget.classList.add("w-16")
      this.labelTargets.forEach(el => el.classList.add("hidden"))
    }
  }
}
