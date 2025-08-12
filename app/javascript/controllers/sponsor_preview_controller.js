import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  fetch (event) {
    event.preventDefault()

    const button = event.currentTarget
    const form = button.closest('form')
    const formData = new FormData(form)

    // Show loading state
    const previewContainer = document.getElementById('sponsor-preview')
    previewContainer.innerHTML = '<div class="card-body"><div class="loading loading-spinner loading-lg"></div><p>Fetching sponsors...</p></div>'

    // Make the fetch request
    fetch('/studio/sponsors/fetch', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        Accept: 'text/html'
      }
    })
      .then(response => {
        if (!response.ok) {
          console.error('Response status:', response.status, response.statusText)
          return response.text().then(text => {
            console.error('Response body:', text)
            throw new Error(`Server responded with ${response.status}: ${response.statusText}`)
          })
        }
        return response.text()
      })
      .then(html => {
        previewContainer.innerHTML = html
      })
      .catch(error => {
        console.error('Full error details:', error)
        previewContainer.innerHTML = `<div class="card-body"><div class="alert alert-error">Failed to fetch sponsors: ${error.message}</div></div>`
      })
  }
}
