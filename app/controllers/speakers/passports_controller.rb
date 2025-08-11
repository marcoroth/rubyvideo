class Speakers::PassportsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_speaker

  def show
    @events_attended = @speaker.events.includes(:organisation).distinct.order(start_date: :desc)
    @talks_given = @speaker.kept_talks.includes(:event).order(date: :desc)
    @first_talk_year = @talks_given.minimum(:date)&.year || Time.current.year
    
    # Get events with stickers
    @events_with_stickers = @events_attended.select(&:sticker?)

    # Get unique countries from events
    @countries_visited = @events_attended.map { |e| e.static_metadata&.country }.compact.uniq.sort_by { |c| c.translations["en"] }

    # Calculate some stats
    @total_talks = @talks_given.count
    @total_events = @events_attended.count
    @years_active = Time.current.year - @first_talk_year + 1

    render layout: "passport"
  end

  private

  def set_speaker
    @speaker = Speaker.includes(:talks).find_by(slug: params[:speaker_slug])
    redirect_to speakers_path, status: :moved_permanently, notice: "Speaker not found" if @speaker.blank?
    redirect_to speaker_passport_path(@speaker.canonical) if @speaker&.canonical.present?
  end
end
