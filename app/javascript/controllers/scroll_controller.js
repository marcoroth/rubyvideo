import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "button", "gradient"]

  connect() {
    // Check initial scroll position
    this.checkScroll()
    
    // Add scroll event listener
    this.containerTarget.addEventListener('scroll', () => this.checkScroll())
  }

  scrollRight() {
    const container = this.containerTarget
    // Scroll by two card widths (2 * 288px) plus the gap (32px)
    container.scrollBy({
      left: (288 * 2) + 32,
      behavior: 'smooth'
    })
  }

  checkScroll() {
    const container = this.containerTarget
    const isAtEnd = container.scrollLeft + container.offsetWidth >= container.scrollWidth - 1
    
    if (isAtEnd) {
      this.buttonTarget.classList.add('hidden')
      this.gradientTarget.classList.add('hidden')
    } else {
      this.buttonTarget.classList.remove('hidden')
      this.gradientTarget.classList.remove('hidden')
    }
  }
} 