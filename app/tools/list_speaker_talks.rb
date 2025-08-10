# frozen_string_literal: true

require_relative "utils/yaml_utils"

class ListSpeakerTalks < RubyLLM::Tool
  description "List all talks of a speaker"
  param :speaker_name, desc: "Speaker full name"

  def execute(speaker_name:)
    name = speaker_name.to_s.strip
    raise ArgumentError, "speaker_name required" if name.empty?
    talks = []
    Dir.glob(Rails.root.join("data", "**", "**", "videos.yml").to_s).sort.each do |path|
      Tools::YamlUtils.read_yaml_array(path).each do |talk|
        if Array(talk["speakers"]).any? { |s| s.to_s.strip.casecmp?(name) }
          talks << talk.merge("_source" => path)
        end
        Array(talk["talks"]).each do |child|
          if Array(child["speakers"]).any? { |s| s.to_s.strip.casecmp?(name) }
            talks << child.merge("_source" => path)
          end
        end
      end
    end
    talks
  rescue => e
    {error: e.message}
  end
end
