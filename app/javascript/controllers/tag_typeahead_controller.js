import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "container"]
  static values = {
    searchUrl: String,
    createUrl: String,
    agendaItemId: Number
  }

  connect() {
    this.selectedIndex = -1
    this.debounceTimer = null
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  onInput() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.search(), 200)
  }

  onKeydown(event) {
    const items = this.dropdownTarget.querySelectorAll("li")

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightItem(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.highlightItem(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
      case "Escape":
        this.hideDropdown()
        break
    }
  }

  async search() {
    const query = this.inputTarget.value.trim()
    if (query.length === 0) {
      this.hideDropdown()
      return
    }

    const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`)
    const tags = await response.json()

    this.renderDropdown(tags, query)
  }

  renderDropdown(tags, query) {
    this.dropdownTarget.innerHTML = ""
    this.selectedIndex = -1

    const exactMatch = tags.some(t => t.name.toLowerCase() === query.toLowerCase())

    tags.forEach(tag => {
      const li = document.createElement("li")
      li.textContent = tag.name
      li.className = "px-3 py-1.5 cursor-pointer hover:bg-indigo-50"
      li.addEventListener("click", () => this.selectTag(tag.name))
      this.dropdownTarget.appendChild(li)
    })

    if (!exactMatch && query.length > 0) {
      const li = document.createElement("li")
      li.innerHTML = `Create <em>${this.escapeHtml(query)}</em>`
      li.className = "px-3 py-1.5 cursor-pointer hover:bg-indigo-50 text-indigo-600 border-t border-gray-100"
      li.addEventListener("click", () => this.selectTag(query))
      this.dropdownTarget.appendChild(li)
    }

    if (this.dropdownTarget.children.length > 0) {
      this.showDropdown()
    } else {
      this.hideDropdown()
    }
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      item.classList.toggle("bg-indigo-50", index === this.selectedIndex)
    })
  }

  async selectTag(tagName) {
    this.hideDropdown()
    this.inputTarget.value = ""

    const formData = new FormData()
    formData.append("tag_name", tagName)
    formData.append("agenda_item_id", this.agendaItemIdValue)

    const response = await fetch(this.createUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    })

    if (response.ok) {
      const html = await response.text()
      window.Turbo.renderStreamMessage(html)
    }
  }

  showDropdown() {
    this.dropdownTarget.classList.remove("hidden")
  }

  hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.selectedIndex = -1
  }

  handleClickOutside(event) {
    if (this.hasContainerTarget && !this.containerTarget.contains(event.target)) {
      this.hideDropdown()
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
