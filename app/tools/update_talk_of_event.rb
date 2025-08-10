# frozen_string_literal: true

require_relative "utils/yaml_utils"

class UpdateTalkOfEvent < RubyLLM::Tool
  description "Update a talk of an event (by video_id or title selector)"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"
  param :selector_json, desc: "JSON like {\"video_id\":\"...\"} or {\"title\":\"...\"}"
  param :attributes_json, desc: "JSON attributes to merge"

  def execute(organisation_slug:, event_slug:, selector_json:, attributes_json:)
    selector = begin
      JSON.parse(selector_json)
    rescue
      {}
    end
    attributes = begin
      JSON.parse(attributes_json)
    rescue
      {}
    end
    file_path = Tools::YamlUtils.ensure_event_videos_file!(organisation_slug: organisation_slug, event_slug: event_slug)
    videos = Tools::YamlUtils.read_yaml_array(file_path)
    idx = if selector["video_id"].to_s.strip != ""
      videos.index { |v| v["video_id"].to_s == selector["video_id"].to_s }
    else
      videos.index { |v| v["title"].to_s == selector["title"].to_s }
    end
    raise ArgumentError, "talk not found" unless idx
    videos[idx] = videos[idx].merge(attributes).compact
    Tools::YamlUtils.write_yaml_array(file_path, videos)
    {status: "ok", organisation_slug: organisation_slug, event_slug: event_slug}
  rescue => e
    {error: e.message}
  end
end
