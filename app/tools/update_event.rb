# frozen_string_literal: true

require_relative "utils/yaml_utils"

class UpdateEvent < RubyLLM::Tool
  description "Update an existing event by slug"
  param :organisation_slug, desc: "Organisation slug"
  param :event_slug, desc: "Event slug"
  param :attributes_json, desc: "JSON object of attributes to merge"

  def execute(organisation_slug:, event_slug:, attributes_json: "{}")
    attributes = begin
      JSON.parse(attributes_json)
    rescue
      {}
    end
    file_path = Rails.root.join("data", organisation_slug, "playlists.yml")
    playlists = Tools::YamlUtils.read_yaml_array(file_path)
    idx = playlists.index { |pl| pl["slug"] == event_slug }
    raise ArgumentError, "event not found: #{event_slug}" unless idx
    playlists[idx] = playlists[idx].merge(Tools::YamlUtils.stringify_keys(attributes)).compact
    Tools::YamlUtils.write_yaml_array(file_path, playlists)
    {status: "ok", organisation_slug: organisation_slug, event_slug: event_slug}
  rescue => e
    {error: e.message}
  end
end
