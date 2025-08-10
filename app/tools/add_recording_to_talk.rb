# frozen_string_literal: true

class AddRecordingToTalk < RubyLLM::Tool
  description "Add (YouTube) recording to a talk"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"
  param :selector_json, desc: "JSON like {\"video_id\":\"...\"} or {\"title\":\"...\"}"
  param :provider, desc: "Video provider (e.g., youtube)"
  param :video_id, desc: "Provider video id"
  param :published_at, desc: "Published at (YYYY-MM-DD)", required: false

  def execute(organisation_slug:, event_slug:, selector_json:, provider:, video_id:, published_at: nil)
    selector = begin
      JSON.parse(selector_json)
    rescue
      {}
    end
    attrs = {video_provider: provider, video_id: video_id}
    attrs[:published_at] = published_at if published_at
    UpdateTalkOfEvent.new.execute(
      organisation_slug: organisation_slug,
      event_slug: event_slug,
      selector_json: selector.to_json,
      attributes_json: attrs.to_json
    )
  rescue => e
    {error: e.message}
  end
end
