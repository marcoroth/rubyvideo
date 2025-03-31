import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "button", "gradient", "card"]

  connect() {
    this.checkScroll()
  }

  scrollRight() {
    const container = this.containerTarget
    const cardWidth = this.cardTargets[0].offsetWidth
    const gap = parseInt(window.getComputedStyle(container.firstElementChild).gap)
    
    // Calculate remaining scroll distance
    const remainingScroll = container.scrollWidth - (container.scrollLeft + container.offsetWidth)
    // Calculate width of two cards plus gap
    const twoCardWidth = (cardWidth * 2) + (gap * 2)
    
    // If remaining scroll is less than or equal to two cards, scroll to end
    container.scrollBy({
      left: remainingScroll,
      behavior: 'smooth'
    })

    // Check scroll position after animation
    this.checkScroll()
  }

  checkScroll() {
    const container = this.containerTarget
    // Add a small buffer (1px) to account for rounding errors
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