# frozen_string_literal: true

require "yaml"
require "fileutils"

module Tools
  module YamlUtils
    module_function

    def read_yaml_array(file_path)
      path = file_path.to_s
      return [] unless File.exist?(path)
      data = YAML.load_file(path) || []
      Array.wrap(data).map { |x| stringify_keys(x || {}) }
    rescue Psych::SyntaxError => e
      raise "Invalid YAML at #{path}: #{e.message}"
    end

    def write_yaml_array(file_path, array)
      FileUtils.mkdir_p(File.dirname(file_path))
      yaml = Array.wrap(array).map { |x| x.compact }.to_yaml
      yaml = yaml.sub("---\n", "") if yaml.start_with?("---\n")
      File.write(file_path, yaml)
      true
    end

    def ensure_event_folder!(organisation_slug:, event_slug:)
      base = Rails.root.join("data", organisation_slug, event_slug)
      FileUtils.mkdir_p(base)
      base
    end

    def ensure_event_videos_file!(organisation_slug:, event_slug:)
      base = ensure_event_folder!(organisation_slug: organisation_slug, event_slug: event_slug)
      file_path = base.join("videos.yml")
      write_yaml_array(file_path, read_yaml_array(file_path)) unless File.exist?(file_path)
      file_path
    end

    def stringify_keys(obj)
      case obj
      when Hash
        obj.transform_keys(&:to_s).transform_values { |v| stringify_keys(v) }
      when Array
        obj.map { |v| stringify_keys(v) }
      else
        obj
      end
    end

    def required!(hash, keys)
      missing = keys.select { |k| hash[k].to_s.strip.empty? }
      raise ArgumentError, "Missing required: #{missing.join(", ")}" if missing.any?
    end
  end
end
