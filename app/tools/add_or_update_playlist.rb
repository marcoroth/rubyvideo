# frozen_string_literal: true

require_relative "utils/yaml_utils"

class AddOrUpdatePlaylist < RubyLLM::Tool
  description "Add or update a playlist (event) under an organisation"
  param :organisation_slug, desc: "Organisation slug"
  param :attributes_json, desc: "JSON for playlist attributes"

  def execute(organisation_slug:, attributes_json:)
    attrs = Tools::YamlUtils.stringify_keys(JSON.parse(attributes_json) rescue {})
    path = Rails.root.join("data", organisation_slug, "playlists.yml")
    FileUtils.mkdir_p(path.dirname)
    playlists = Tools::YamlUtils.read_yaml_array(path)
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
    idx = playlists.index { |pl| pl["slug"] == slug } || (record["id"] && playlists.index { |pl| pl["id"] == record["id"] })
    if idx
      playlists[idx] = playlists[idx].merge(record)
    else
      playlists << record
    end
    Tools::YamlUtils.write_yaml_array(path, playlists)
    {status: "ok", organisation_slug: organisation_slug, playlist_slug: slug}
  rescue => e
    {error: e.message}
  end
end