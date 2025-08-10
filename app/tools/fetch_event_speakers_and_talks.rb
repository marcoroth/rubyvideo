# frozen_string_literal: true

class FetchEventSpeakersAndTalks < RubyLLM::Tool
  description "Fetch speakers and talks for an event"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"

  def execute(organisation_slug:, event_slug:)
    {speakers: FetchEventSpeakers.new.execute(organisation_slug: organisation_slug, event_slug: event_slug), talks: ListEventTalks.new.execute(organisation_slug: organisation_slug, event_slug: event_slug)}
  rescue => e
    {error: e.message}
  end
end
