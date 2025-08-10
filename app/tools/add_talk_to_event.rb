# frozen_string_literal: true

require_relative "utils/yaml_utils"

class AddTalkToEvent < RubyLLM::Tool
  description "Add a talk to an event"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"
  param :attributes_json, desc: "JSON object for talk (title, event_name, speakers, video_id, etc.)"

  def execute(organisation_slug:, event_slug:, attributes_json:)
    attributes = begin
      JSON.parse(attributes_json)
    rescue
      {}
    end
    Tools::YamlUtils.required!(attributes, %w[title event_name])
    file_path = Tools::YamlUtils.ensure_event_videos_file!(organisation_slug: organisation_slug, event_slug: event_slug)
    videos = Tools::YamlUtils.read_yaml_array(file_path)
    if attributes["video_id"].to_s.strip != ""
      idx = videos.index { |v| v["video_id"] == attributes["video_id"] }
      if idx
        videos[idx] = videos[idx].merge(attributes).compact
      else
        videos << {"description" => "", "speakers" => [], "video_provider" => "youtube"}.merge(attributes).compact
      end
    else
      videos << {"description" => "", "speakers" => [], "video_provider" => "youtube"}.merge(attributes).compact
    end
    Tools::YamlUtils.write_yaml_array(file_path, videos)
    {status: "ok", organisation_slug: organisation_slug, event_slug: event_slug}
  rescue => e
    {error: e.message}
  end
end
