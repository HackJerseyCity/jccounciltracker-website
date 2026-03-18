import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"]

  edit() {
    const input = this.input
    this.originalValue = input.value
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    input.focus()
    input.select()
  }

  save() {
    const input = this.input
    if (input.value.trim() === "" || input.value === this.originalValue) {
      this.cancel()
      return
    }
    this.formTarget.requestSubmit()
  }

  cancel() {
    this.input.value = this.originalValue
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    } else if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.save()
    }
  }

  get input() {
    return this.formTarget.querySelector("textarea, input[type=text]")
  }
}
