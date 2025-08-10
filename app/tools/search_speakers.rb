# frozen_string_literal: true

require_relative "utils/yaml_utils"

class SearchSpeakers < RubyLLM::Tool
  description "Search speakers by name substring"
  param :query, desc: "Text to search in speaker names"

  def execute(query:)
    q = query.to_s.strip.downcase
    return [] if q.empty?
    path = Rails.root.join("data", "speakers.yml")
    Tools::YamlUtils.read_yaml_array(path).select { |s| s["name"].to_s.downcase.include?(q) }
  rescue => e
    {error: e.message}
  end
end
