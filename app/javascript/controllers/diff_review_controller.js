import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "counter"]

  connect() {
    this.updateCounter()
  }

  selectAll() {
    this.checkboxTargets.forEach(cb => cb.checked = true)
    this.updateCounter()
  }

  selectNone() {
    this.checkboxTargets.forEach(cb => cb.checked = false)
    this.updateCounter()
  }

  updateCounter() {
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    const total = this.checkboxTargets.length
    this.counterTarget.textContent = `${checked} of ${total} selected`
  }
}
