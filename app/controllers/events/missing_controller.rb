class Events::MissingController < ApplicationController
  skip_before_action :authenticate_user!

  # GET /events/missing
  def index
    @back_path = archive_events_path

    all_events = Event.canonical
      .includes(:organisation, :talks, :sponsors)
      .order(start_date: :desc)

    @events_with_missing_data = all_events.map { |event|
      missing_data = []

      missing_data << :talks if event.talks_count == 0
      missing_data << :cfp if event.cfp_link.blank?
      missing_data << :website if event.website.blank?
      missing_data << :schedule unless event.schedule.exist?
      missing_data << :sponsors if event.sponsors.empty?
      missing_data << :dates if event.start_date.blank? || event.end_date.blank?
      missing_data << :location if event.static_metadata.location.blank? || event.static_metadata.location == "Earth"

      [event, missing_data]
    }.reject { |event, missing_data| missing_data.empty? }

    @events_missing_data = @events_with_missing_data.map(&:first)
    @events_by_year = @events_missing_data.group_by { |event| event.start_date&.year || "Unknown" }
    @events_missing_info = @events_with_missing_data.to_h

    all_missing = all_events.map { |event|
      missing_data = []

      missing_data << :talks if event.talks_count == 0
      missing_data << :cfp if event.cfp_link.blank?
      missing_data << :website if event.website.blank?
      missing_data << :schedule unless event.schedule.exist?
      missing_data << :sponsors if event.sponsors.empty?
      missing_data << :dates if event.start_date.blank? || event.end_date.blank?
      missing_data << :location if event.static_metadata.location.blank? || event.static_metadata.location == "Earth"

      missing_data
    }.reject(&:empty?)

    @filter_counts = {
      talks: all_missing.count { |missing| missing.include?(:talks) },
      cfp: all_missing.count { |missing| missing.include?(:cfp) },
      website: all_missing.count { |missing| missing.include?(:website) },
      schedule: all_missing.count { |missing| missing.include?(:schedule) },
      sponsors: all_missing.count { |missing| missing.include?(:sponsors) },
      dates: all_missing.count { |missing| missing.include?(:dates) },
      location: all_missing.count { |missing| missing.include?(:location) }
    }
  end
end
