import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["colorPicker", "textField"]

  connect() {
    this.syncFromText()
  }

  syncFromColor() {
    const colorValue = this.colorPickerTarget.value
    this.textFieldTarget.value = colorValue
  }

  syncFromText() {
    const textValue = this.textFieldTarget.value
    // Only sync if it's a simple hex color (not a gradient)
    if (textValue && textValue.match(/^#[0-9A-Fa-f]{6}$/)) {
      this.colorPickerTarget.value = textValue
    }
  }
}