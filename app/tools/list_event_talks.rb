# frozen_string_literal: true

require_relative "utils/yaml_utils"

class ListEventTalks < RubyLLM::Tool
  description "List talks of an event"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"

  def execute(organisation_slug:, event_slug:)
    file_path = Tools::YamlUtils.ensure_event_videos_file!(organisation_slug: organisation_slug, event_slug: event_slug)
    Tools::YamlUtils.read_yaml_array(file_path)
  rescue => e
    {error: e.message}
  end
end
