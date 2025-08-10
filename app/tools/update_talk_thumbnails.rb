# frozen_string_literal: true

class UpdateTalkThumbnails < RubyLLM::Tool
  description "Add/update thumbnail_* fields on a talk"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"
  param :selector_json, desc: "JSON like {\"video_id\":\"...\"} or {\"title\":\"...\"}"
  param :thumbnails_json, desc: "JSON like {thumbnail_xs, thumbnail_sm, thumbnail_md, thumbnail_lg, thumbnail_xl}"

  def execute(organisation_slug:, event_slug:, selector_json:, thumbnails_json:)
    selector = begin
      JSON.parse(selector_json)
    rescue
      {}
    end
    thumbs = begin
      JSON.parse(thumbnails_json)
    rescue
      {}
    end
    UpdateTalkOfEvent.new.execute(
      organisation_slug: organisation_slug,
      event_slug: event_slug,
      selector_json: selector.to_json,
      attributes_json: thumbs.to_json
    )
  rescue => e
    {error: e.message}
  end
end
