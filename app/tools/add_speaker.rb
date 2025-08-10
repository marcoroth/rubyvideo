# frozen_string_literal: true

require_relative "utils/yaml_utils"

class AddSpeaker < RubyLLM::Tool
  description "Add or update a speaker in data/speakers.yml"
  param :attributes_json, desc: "JSON object for speaker (name required)"

  def execute(attributes_json:)
    attrs = Tools::YamlUtils.stringify_keys(JSON.parse(attributes_json) rescue {})
    raise ArgumentError, "Missing speaker name" if attrs["name"].to_s.strip.empty?
    path = Rails.root.join("data", "speakers.yml")
    speakers = Tools::YamlUtils.read_yaml_array(path)
    idx = speakers.index { |s| s["name"].to_s.strip.casecmp?(attrs["name"].to_s.strip) }
    record = {
      "twitter" => nil,
      "github" => nil,
      "bluesky" => nil,
      "mastodon" => nil,
      "website" => nil,
      "company" => nil,
      "country_code" => nil
    }.merge(attrs).compact
    if idx
      speakers[idx] = speakers[idx].merge(record)
    else
      speakers << record
    end
    Tools::YamlUtils.write_yaml_array(path, speakers)
    {status: "ok", name: attrs["name"]}
  rescue => e
    {error: e.message}
  end
end