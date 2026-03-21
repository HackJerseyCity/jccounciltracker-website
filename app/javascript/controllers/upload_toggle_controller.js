import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileTab", "urlTab", "filePanel", "urlPanel"]

  showFile() {
    this.filePanelTarget.classList.remove("hidden")
    this.urlPanelTarget.classList.add("hidden")
    this.fileTabTarget.classList.replace("bg-gray-100", "bg-blue-600")
    this.fileTabTarget.classList.replace("text-gray-700", "text-white")
    this.fileTabTarget.classList.remove("hover:bg-gray-200")
    this.urlTabTarget.classList.replace("bg-blue-600", "bg-gray-100")
    this.urlTabTarget.classList.replace("text-white", "text-gray-700")
    this.urlTabTarget.classList.add("hover:bg-gray-200")
  }

  showUrl() {
    this.urlPanelTarget.classList.remove("hidden")
    this.filePanelTarget.classList.add("hidden")
    this.urlTabTarget.classList.replace("bg-gray-100", "bg-blue-600")
    this.urlTabTarget.classList.replace("text-gray-700", "text-white")
    this.urlTabTarget.classList.remove("hover:bg-gray-200")
    this.fileTabTarget.classList.replace("bg-blue-600", "bg-gray-100")
    this.fileTabTarget.classList.replace("text-white", "text-gray-700")
    this.fileTabTarget.classList.add("hover:bg-gray-200")
  }
}
