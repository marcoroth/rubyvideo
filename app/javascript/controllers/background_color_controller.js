import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ["image"]

  connect () {
    const canvas = document.createElement("canvas")
    canvas.width = 1
    canvas.height = 1

    const context = canvas.getContext("2d")

    context.drawImage(this.imageTarget, 0, 0)

    const imageData = context.getImageData(0, 0, 1, 1)
    const [r, g, b, a] = imageData.data

    const rgba = `rgba(${r},${g},${b},${a})`

    console.log(rgba)

    this.element.style.backgroundColor = rgba
    this.imageTarget.classList.remove("hidden")

  }
}
