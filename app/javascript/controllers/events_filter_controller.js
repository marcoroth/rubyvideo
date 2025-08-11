import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterBadge", "countAll", "countTalks", "countCfp", "countWebsite", "countSchedule", "countSponsors", "countDates", "countLocation", "statusText"]

  connect() {
    this.allCards = document.querySelectorAll('.event-card')
    this.updateCounts()
  }

  filterAll() {
    this.showAllCards()
    this.updateActiveBadge('all')
    this.updateStatusText('Total events missing data', this.allCards.length)
  }

  filter(event) {
    const filterType = event.currentTarget.dataset.filter
    this.filterByType(filterType)
    this.updateActiveBadge(filterType)

    const visibleCount = document.querySelectorAll('.event-card:not(.hidden)').length
    this.updateStatusText(`Events missing ${filterType}`, visibleCount)
  }

  showAllCards() {
    this.allCards.forEach(card => {
      card.classList.remove('hidden')
      card.closest('.space-y-8 > div').classList.remove('hidden') // Show year sections
    })
    this.updateYearSections()
  }

  filterByType(type) {
    this.allCards.forEach(card => {
      const hasMissingData = card.dataset[`missing${this.capitalize(type)}`] === 'true'

      if (hasMissingData) {
        card.classList.remove('hidden')
      } else {
        card.classList.add('hidden')
      }
    })
    this.updateYearSections()
  }

  updateYearSections() {
    document.querySelectorAll('.space-y-8 > div').forEach(yearSection => {
      const visibleCards = yearSection.querySelectorAll('.event-card:not(.hidden)')
      if (visibleCards.length === 0) {
        yearSection.classList.add('hidden')
      } else {
        yearSection.classList.remove('hidden')

        const countSpan = yearSection.querySelector('h2 span')

        if (countSpan) {
          const eventWord = visibleCards.length === 1 ? 'event' : 'events'
          countSpan.textContent = `(${visibleCards.length} ${eventWord})`
        }
      }
    })
  }

  updateActiveBadge(activeFilter) {
    this.filterBadgeTargets.forEach(badge => {
      const filter = badge.dataset.filter
      badge.classList.remove('badge-primary', 'badge-error', 'badge-warning', 'badge-info', 'badge-secondary', 'badge-accent', 'badge-neutral', 'badge-ghost')

      if (filter === activeFilter) {
        switch (filter) {
          case 'all':
            badge.classList.add('badge-primary')
            break
          case 'talks':
            badge.classList.add('badge-error')
            break
          case 'cfp':
            badge.classList.add('badge-warning')
            break
          case 'website':
            badge.classList.add('badge-info')
            break
          case 'schedule':
            badge.classList.add('badge-secondary')
            break
          case 'sponsors':
            badge.classList.add('badge-accent')
            break
          case 'dates':
            badge.classList.add('badge-neutral')
            break
          case 'location':
            badge.classList.add('badge-ghost')
            break
        }
      } else {
        badge.classList.add('badge-outline')
      }
    })
  }

  updateCounts() {
    const counts = {
      all: this.allCards.length,
      talks: this.countByAttribute('missingTalks'),
      cfp: this.countByAttribute('missingCfp'),
      website: this.countByAttribute('missingWebsite'),
      schedule: this.countByAttribute('missingSchedule'),
      sponsors: this.countByAttribute('missingSponsors'),
      dates: this.countByAttribute('missingDates'),
      location: this.countByAttribute('missingLocation')
    }

    if (this.hasCountAllTarget) this.countAllTarget.textContent = counts.all
    if (this.hasCountTalksTarget) this.countTalksTarget.textContent = counts.talks
    if (this.hasCountCfpTarget) this.countCfpTarget.textContent = counts.cfp
    if (this.hasCountWebsiteTarget) this.countWebsiteTarget.textContent = counts.website
    if (this.hasCountScheduleTarget) this.countScheduleTarget.textContent = counts.schedule
    if (this.hasCountSponsorsTarget) this.countSponsorsTarget.textContent = counts.sponsors
    if (this.hasCountDatesTarget) this.countDatesTarget.textContent = counts.dates
    if (this.hasCountLocationTarget) this.countLocationTarget.textContent = counts.location
  }

  countByAttribute(attribute) {
    return Array.from(this.allCards).filter(card => card.dataset[attribute] === 'true').length
  }

  updateStatusText(prefix, count) {
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.innerHTML = `${prefix}: <strong>${count}</strong>`
    }
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }
}
