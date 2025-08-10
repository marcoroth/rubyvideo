require "yaml"
require "fileutils"

# Minimal helpers to create/update YAML data under the `data/` folder.
# Designed to be called from rake tasks, CLI scripts, or AI tools.
module DataTools
  module_function

  # Public API

  def add_organisation!(attributes)
    attributes = stringify_keys(attributes)
    ensure_data_base!

    file_path = Rails.root.join("data", "organisations.yml")
    organisations = read_yaml_array(file_path)

    # Prefer slug as stable key; fallback to name
    slug = attributes["slug"] || slugify(attributes["name"])
    raise ArgumentError, "Missing organisation name" if attributes["name"].to_s.strip.empty?

    existing_index = organisations.index { |o| (o["slug"] || slugify(o["name"])) == slug }

    record = default_organisation.merge(attributes).merge("slug" => slug)

    if existing_index
      organisations[existing_index] = organisations[existing_index].merge(record).compact
    else
      organisations << record.compact
    end

    write_yaml_array(file_path, organisations)

    {status: "ok", slug: slug}
  end

  def add_or_update_playlist!(organisation_slug:, attributes:)
    organisation_slug = organisation_slug.to_s
    raise ArgumentError, "organisation_slug required" if organisation_slug.empty?
    attributes = stringify_keys(attributes)

    file_path = Rails.root.join("data", organisation_slug, "playlists.yml")
    FileUtils.mkdir_p(file_path.dirname)
    playlists = read_yaml_array(file_path)

    # derive slug if missing
    playlist_slug = attributes["slug"] || slugify(attributes["title"] || attributes["id"])
    record = default_playlist.merge(attributes).merge("slug" => playlist_slug).compact

    # Upsert by explicit id if present, else by slug
    idx = if record.key?("id")
      playlists.index { |pl| pl["id"] == record["id"] }
    end
    idx = playlists.index { |pl| pl["slug"] == record["slug"] } if idx.nil?

    if idx
      playlists[idx] = playlists[idx].merge(record)
    else
      playlists << record
    end

    write_yaml_array(file_path, playlists)
    {status: "ok", organisation_slug: organisation_slug, playlist_slug: playlist_slug}
  end

  # Event helpers (playlist entry == event)
  def add_event!(organisation_slug:, attributes:)
    add_or_update_playlist!(organisation_slug: organisation_slug, attributes: attributes)
  end

  def update_event!(organisation_slug:, event_slug:, attributes:)
    organisation_slug = organisation_slug.to_s
    event_slug = event_slug.to_s
    raise ArgumentError, "organisation_slug required" if organisation_slug.empty?
    raise ArgumentError, "event_slug required" if event_slug.empty?

    file_path = Rails.root.join("data", organisation_slug, "playlists.yml")
    playlists = read_yaml_array(file_path)
    idx = playlists.index { |pl| pl["slug"] == event_slug }
    raise ArgumentError, "event not found: #{event_slug}" unless idx

    playlists[idx] = playlists[idx].merge(stringify_keys(attributes)).compact
    write_yaml_array(file_path, playlists)
    {status: "ok", organisation_slug: organisation_slug, event_slug: event_slug}
  end

  def ensure_event_folder!(organisation_slug:, event_slug:)
    base = Rails.root.join("data", organisation_slug, event_slug)
    FileUtils.mkdir_p(base)
    base
  end

  def ensure_event_videos_file!(organisation_slug:, event_slug:)
    base = ensure_event_folder!(organisation_slug: organisation_slug, event_slug: event_slug)
    file_path = base.join("videos.yml")
    write_yaml_array(file_path, read_yaml_array(file_path)) unless file_path.exist?
    file_path
  end

  def add_video!(organisation_slug:, event_slug:, attributes:)
    organisation_slug = organisation_slug.to_s
    event_slug = event_slug.to_s
    raise ArgumentError, "organisation_slug required" if organisation_slug.empty?
    raise ArgumentError, "event_slug required" if event_slug.empty?

    attributes = stringify_keys(attributes)
    required!(attributes, %w[title event_name])

    file_path = ensure_event_videos_file!(organisation_slug: organisation_slug, event_slug: event_slug)
    videos = read_yaml_array(file_path)

    # Try to upsert by video_id if present; otherwise append new
    if attributes["video_id"].to_s.strip != ""
      idx = videos.index { |v| v["video_id"] == attributes["video_id"] }
      if idx
        videos[idx] = videos[idx].merge(attributes).compact
      else
        videos << default_video.merge(attributes).compact
      end
    else
      videos << default_video.merge(attributes).compact
    end

    write_yaml_array(file_path, videos)
    {status: "ok", organisation_slug: organisation_slug, event_slug: event_slug}
  end

  # Update a talk within an event by selector ({video_id:} or {title:})
  def update_video!(organisation_slug:, event_slug:, selector:, attributes:)
    organisation_slug = organisation_slug.to_s
    event_slug = event_slug.to_s
    raise ArgumentError, "organisation_slug required" if organisation_slug.empty?
    raise ArgumentError, "event_slug required" if event_slug.empty?

    selector = stringify_keys(selector || {})
    raise ArgumentError, "selector must include video_id or title" if selector["video_id"].to_s.strip == "" && selector["title"].to_s.strip == ""

    file_path = ensure_event_videos_file!(organisation_slug: organisation_slug, event_slug: event_slug)
    videos = read_yaml_array(file_path)

    idx = if selector["video_id"].to_s.strip != ""
      videos.index { |v| v["video_id"].to_s == selector["video_id"].to_s }
    else
      videos.index { |v| v["title"].to_s == selector["title"].to_s }
    end
    raise ArgumentError, "talk not found" unless idx

    videos[idx] = videos[idx].merge(stringify_keys(attributes)).compact
    write_yaml_array(file_path, videos)
    {status: "ok", organisation_slug: organisation_slug, event_slug: event_slug}
  end

  # Convenience wrappers
  def update_video_thumbnails!(organisation_slug:, event_slug:, selector:, thumbnails:)
    update_video!(organisation_slug: organisation_slug, event_slug: event_slug, selector: selector, attributes: stringify_keys(thumbnails))
  end

  def update_video_slides!(organisation_slug:, event_slug:, selector:, slides_url:)
    update_video!(organisation_slug: organisation_slug, event_slug: event_slug, selector: selector, attributes: {slides_url: slides_url})
  end

  def add_video_recording!(organisation_slug:, event_slug:, selector:, provider:, video_id:, published_at: nil)
    attrs = {video_provider: provider, video_id: video_id}
    attrs[:published_at] = published_at if published_at
    update_video!(organisation_slug: organisation_slug, event_slug: event_slug, selector: selector, attributes: attrs)
  end

  # Read operations
  def list_event_talks(organisation_slug:, event_slug:)
    file_path = ensure_event_videos_file!(organisation_slug: organisation_slug, event_slug: event_slug)
    read_yaml_array(file_path)
  end

  def list_speaker_talks(speaker_name:)
    name = speaker_name.to_s.strip
    raise ArgumentError, "speaker_name required" if name.empty?
    talks = []
    Dir.glob(Rails.root.join("data", "**", "**", "videos.yml").to_s).sort.each do |path|
      read_yaml_array(path).each do |talk|
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
  end

  def search_speakers(query:)
    q = query.to_s.strip.downcase
    return [] if q.empty?
    file_path = Rails.root.join("data", "speakers.yml")
    read_yaml_array(file_path).select { |s| s["name"].to_s.downcase.include?(q) }
  end

  def fetch_event_speakers(organisation_slug:, event_slug:)
    talks = list_event_talks(organisation_slug: organisation_slug, event_slug: event_slug)
    speakers = talks.flat_map { |t| Array(t["speakers"]) } + talks.flat_map { |t| Array(t["talks"]).flat_map { |c| Array(c["speakers"]) } }
    speakers.compact.map(&:to_s).map(&:strip).reject(&:empty?).uniq
  end

  def fetch_event_speakers_and_talks(organisation_slug:, event_slug:)
    talks = list_event_talks(organisation_slug: organisation_slug, event_slug: event_slug)
    {speakers: fetch_event_speakers(organisation_slug: organisation_slug, event_slug: event_slug), talks: talks}
  end

  # Discovery
  def list_all_events
    events = []
    Dir.glob(Rails.root.join("data", "*", "playlists.yml").to_s).sort.each do |path|
      org = File.basename(File.dirname(path))
      read_yaml_array(path).each do |pl|
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
  end

  def add_speaker!(attributes)
    attributes = stringify_keys(attributes)
    raise ArgumentError, "Missing speaker name" if attributes["name"].to_s.strip.empty?

    file_path = Rails.root.join("data", "speakers.yml")
    speakers = read_yaml_array(file_path)

    idx = speakers.index { |s| s["name"].to_s.strip.casecmp?(attributes["name"].to_s.strip) }
    record = default_speaker.merge(attributes).compact

    if idx
      speakers[idx] = speakers[idx].merge(record)
    else
      speakers << record
    end

    write_yaml_array(file_path, speakers)
    {status: "ok", name: attributes["name"]}
  end

  # Utilities

  def read_yaml_array(file_path)
    return [] unless File.exist?(file_path)
    data = YAML.load_file(file_path) || []
    Array.wrap(data).map { |x| stringify_keys(x || {}) }
  rescue Psych::SyntaxError => e
    raise "Invalid YAML at #{file_path}: #{e.message}"
  end

  def write_yaml_array(file_path, array)
    FileUtils.mkdir_p(File.dirname(file_path))
    yaml = Array.wrap(array).map { |x| x.compact }.to_yaml
    # drop document header to match project style in many files
    yaml = yaml.sub("---\n", "") if yaml.start_with?("---\n")
    File.write(file_path, yaml)
    true
  end

  def ensure_data_base!
    FileUtils.mkdir_p(Rails.root.join("data"))
  end

  def slugify(value)
    value.to_s.parameterize
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

  # Default shapes

  def default_organisation
    {
      "website" => nil,
      "twitter" => nil,
      "youtube_channel_name" => nil,
      "kind" => "conference",
      "frequency" => "yearly",
      "playlist_matcher" => nil,
      "language" => "english",
      "youtube_channel_id" => nil,
      "default_country_code" => nil
    }
  end

  def default_playlist
    {
      "location" => nil,
      "description" => "",
      "start_date" => nil,
      "end_date" => nil,
      "channel_id" => nil,
      "year" => nil,
      "videos_count" => 0,
      "metadata_parser" => "Youtube::VideoMetadata",
      "website" => nil
    }
  end

  def default_video
    {
      "description" => "",
      "speakers" => [],
      "video_provider" => "youtube"
    }
  end

  def default_speaker
    {
      "twitter" => nil,
      "github" => nil,
      "bluesky" => nil,
      "mastodon" => nil,
      "website" => nil,
      "company" => nil,
      "country_code" => nil
    }
  end
end
