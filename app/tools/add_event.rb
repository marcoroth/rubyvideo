# frozen_string_literal: true

require_relative "utils/yaml_utils"

class AddEvent < RubyLLM::Tool
  description "Add a new event (playlist entry) under data/{org}/playlists.yml"
  param :organisation_slug, desc: "Organisation slug"
  param :attributes_json, desc: "JSON object of event attributes (e.g., title, start_date)", required: false

  def execute(organisation_slug:, attributes_json: "{}")
    attributes = begin
      JSON.parse(attributes_json)
    rescue
      {}
    end
    Tools::YamlUtils.ensure_event_folder!(organisation_slug: organisation_slug, event_slug: Tools::YamlUtils.stringify_keys(attributes)["slug"] || Tools::YamlUtils.stringify_keys(attributes)["title"].to_s.parameterize)
    # upsert into playlists.yml
    file_path = Rails.root.join("data", organisation_slug, "playlists.yml")
    playlists = Tools::YamlUtils.read_yaml_array(file_path)
    attrs = Tools::YamlUtils.stringify_keys(attributes)
    slug = attrs["slug"] || attrs["title"].to_s.parameterize
    record = {
      "location" => nil,
      "description" => "",
      "start_date" => nil,
      "end_date" => nil,
      "channel_id" => nil,
      "year" => nil,
      "videos_count" => 0,
      "metadata_parser" => "Youtube::VideoMetadata",
      "website" => nil
    }.merge(attrs).merge("slug" => slug).compact
    idx = playlists.index { |pl| pl["slug"] == slug } || playlists.index { |pl| pl["id"] == attrs["id"] }
    if idx
      playlists[idx] = playlists[idx].merge(record)
    else
      playlists << record
    end
    Tools::YamlUtils.write_yaml_array(file_path, playlists)
    {status: "ok", organisation_slug: organisation_slug, event_slug: slug}
  rescue => e
    {error: e.message}
  end
end
