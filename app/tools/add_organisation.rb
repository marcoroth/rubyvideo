# frozen_string_literal: true

require_relative "utils/yaml_utils"

class AddOrganisation < RubyLLM::Tool
  description "Add or update an organisation in data/organisations.yml"
  param :attributes_json, desc: "JSON object for organisation (name, slug, website, etc.)"

  def execute(attributes_json:)
    attrs = begin
      JSON.parse(attributes_json)
    rescue
      {}
    end
    attrs = Tools::YamlUtils.stringify_keys(attrs)
    raise ArgumentError, "Missing organisation name" if attrs["name"].to_s.strip.empty?
    slug = attrs["slug"] || attrs["name"].to_s.parameterize
    path = Rails.root.join("data", "organisations.yml")
    orgs = Tools::YamlUtils.read_yaml_array(path)
    idx = orgs.index { |o| (o["slug"] || o["name"].to_s.parameterize) == slug }
    record = {
      "website" => nil,
      "twitter" => nil,
      "youtube_channel_name" => nil,
      "kind" => "conference",
      "frequency" => "yearly",
      "playlist_matcher" => nil,
      "language" => "english",
      "youtube_channel_id" => nil,
      "default_country_code" => nil
    }.merge(attrs).merge("slug" => slug).compact
    if idx
      orgs[idx] = orgs[idx].merge(record).compact
    else
      orgs << record
    end
    Tools::YamlUtils.write_yaml_array(path, orgs)
    {status: "ok", slug: slug}
  rescue => e
    {error: e.message}
  end
end
