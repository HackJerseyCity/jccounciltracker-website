import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "matchType", "typeButton"]

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      if (this.inputTarget.value.trim() !== "") {
        this.element.requestSubmit()
      }
    }
  }

  toggleType() {
    const current = this.matchTypeTarget.value
    if (current === "keyword") {
      this.matchTypeTarget.value = "phrase"
      this.typeButtonTarget.textContent = "P"
    } else {
      this.matchTypeTarget.value = "keyword"
      this.typeButtonTarget.textContent = "K"
    }
  }
}
