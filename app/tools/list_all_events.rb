# frozen_string_literal: true

require_relative "utils/yaml_utils"

class ListAllEvents < RubyLLM::Tool
  description "List all events (organisation_slug, title, slug, dates)"

  def execute
    events = []
    Dir.glob(Rails.root.join("data", "*", "playlists.yml").to_s).sort.each do |path|
      org = File.basename(File.dirname(path))
      Tools::YamlUtils.read_yaml_array(path).each do |pl|
        events << {
          organisation_slug: org,
          title: pl["title"] || pl["name"],
          slug: pl["slug"],
          start_date: pl["start_date"],
          end_date: pl["end_date"],
          year: pl["year"]
        }.compact
      end
    end
    events
  rescue => e
    {error: e.message}
  end
end
