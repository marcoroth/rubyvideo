module Studio
  class YAMLService
    DATA_PATH = Rails.root.join("data")

    class << self
      # Use Static models for reading
      def read_organizations
        file_path = DATA_PATH.join("organisations.yml")
        return [] unless File.exist?(file_path)
        YAML.load_file(file_path) || []
      end

      def write_organizations(organizations)
        file_path = DATA_PATH.join("organisations.yml")
        # Clean up nil values for each organization
        clean_orgs = organizations.map do |org|
          org.compact
        end
        yaml = clean_orgs.to_yaml
        # Add newline before each organization entry for readability
        yaml = yaml.gsub(/^- name:/, "\n- name:")
        # Remove the extra newline at the beginning if it exists
        yaml = yaml.sub(/\A\n/, "")
        File.write(file_path, yaml)
      end

      def read_speakers
        Static::Speaker.all.map(&:attributes)
      end

      def write_speakers(speakers)
        file_path = DATA_PATH.join("speakers.yml")
        File.write(file_path, speakers.to_yaml)
      end

      def read_event_videos(org_slug, event_slug)
        # Use Static::Video with filtering
        Static::Video.all.select { |v| v.__file_path&.include?("#{org_slug}/#{event_slug}/") }.map(&:attributes)
      end

      def write_event_videos(org_slug, event_slug, videos)
        dir_path = DATA_PATH.join(org_slug, event_slug)
        FileUtils.mkdir_p(dir_path)
        file_path = dir_path.join("videos.yml")

        yaml = videos.to_yaml
        # Format for readability
        yaml = yaml
          .gsub("- title:", "\n- title:")
          .gsub("speakers:\n  -", "speakers:\n    -")

        File.write(file_path, yaml)
      end

      def read_event_sponsors(org_slug, event_slug)
        file_path = DATA_PATH.join(org_slug, event_slug, "sponsors.yml")
        return [] unless File.exist?(file_path)
        YAML.load_file(file_path) || []
      end

      def write_event_sponsors(org_slug, event_slug, sponsors)
        dir_path = DATA_PATH.join(org_slug, event_slug)
        FileUtils.mkdir_p(dir_path)
        file_path = dir_path.join("sponsors.yml")
        File.write(file_path, sponsors.to_yaml)
      end

      def read_event_schedule(org_slug, event_slug)
        file_path = DATA_PATH.join(org_slug, event_slug, "schedule.yml")
        return {} unless File.exist?(file_path)
        YAML.load_file(file_path) || {}
      end

      def write_event_schedule(org_slug, event_slug, schedule)
        dir_path = DATA_PATH.join(org_slug, event_slug)
        FileUtils.mkdir_p(dir_path)
        file_path = dir_path.join("schedule.yml")
        File.write(file_path, schedule.to_yaml)
      end

      def read_playlists(org_slug)
        file_path = DATA_PATH.join(org_slug, "playlists.yml")
        return [] unless File.exist?(file_path)
        YAML.load_file(file_path) || []
      end

      def write_playlists(org_slug, playlists)
        dir_path = DATA_PATH.join(org_slug)
        FileUtils.mkdir_p(dir_path)
        file_path = dir_path.join("playlists.yml")
        
        yaml = playlists.to_yaml
        # Add newline before each playlist entry for readability
        yaml = yaml.gsub(/^- id:/, "\n- id:")
        # Remove the extra newline at the beginning if it exists
        yaml = yaml.sub(/\A\n/, "")
        
        File.write(file_path, yaml)
      end

      def organization_exists?(slug)
        Dir.exist?(DATA_PATH.join(slug))
      end

      def event_exists?(org_slug, event_slug)
        Dir.exist?(DATA_PATH.join(org_slug, event_slug))
      end

      def list_organization_events(org_slug)
        pattern = DATA_PATH.join(org_slug, "*")
        Dir.glob(pattern).select { |f| File.directory?(f) }.map { |f| File.basename(f) }
      end

      def create_event_directory(org_slug, event_slug)
        dir_path = DATA_PATH.join(org_slug, event_slug)
        FileUtils.mkdir_p(dir_path)
      end
    end
  end
end
