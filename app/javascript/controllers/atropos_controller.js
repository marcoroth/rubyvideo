import { Controller } from '@hotwired/stimulus'

import 'atropos/css'

import Atropos from 'atropos'

export default class extends Controller {
  connect () {
    console.log('connect')
    this.atropos = Atropos(this.options)
  }

  get options () {
    return {
      el: this.element,
      rotateXMax: 1,
      rotateYMax: 1
    }
  }
}
