# frozen_string_literal: true

class FetchEventSpeakers < RubyLLM::Tool
  description "Fetch speakers of an event"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"

  def execute(organisation_slug:, event_slug:)
    talks = ListEventTalks.new.execute(organisation_slug: organisation_slug, event_slug: event_slug)
    speakers = talks.flat_map { |t| Array(t["speakers"]) } + talks.flat_map { |t| Array(t["talks"]).flat_map { |c| Array(c["speakers"]) } }
    speakers.compact.map(&:to_s).map(&:strip).reject(&:empty?).uniq
  rescue => e
    {error: e.message}
  end
end
