# frozen_string_literal: true

class UpdateTalkSlides < RubyLLM::Tool
  description "Add/update slides_url for a talk"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"
  param :selector_json, desc: "JSON like {\"video_id\":\"...\"} or {\"title\":\"...\"}"
  param :slides_url, desc: "Slides URL"

  def execute(organisation_slug:, event_slug:, selector_json:, slides_url:)
    selector = begin
      JSON.parse(selector_json)
    rescue
      {}
    end
    UpdateTalkOfEvent.new.execute(
      organisation_slug: organisation_slug,
      event_slug: event_slug,
      selector_json: selector.to_json,
      attributes_json: {slides_url: slides_url}.to_json
    )
  rescue => e
    {error: e.message}
  end
end
