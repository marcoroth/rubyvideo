# frozen_string_literal: true

# Rake tasks that wrap DataTools methods for CLI usage and automation.
# Usage examples:
#   bin/rails "data:add_org[{\"name\":\"MyConf\"}]"
#   echo '{"title":"Talk","event_name":"MyConf 2025"}' | bin/rails data:add_video[org_slug,event_slug]

namespace :data do
  desc "Add or update an organisation in data/organisations.yml (args: json)"
  task :add_org, [:json] => :environment do |_t, args|
    require "data_tools"
    payload = args[:json] && JSON.parse(args[:json])
    payload ||= JSON.parse($stdin.read)
    result = DataTools.add_organisation!(payload)
    puts(result.to_json)
  end

  desc "Add or update a playlist in data/{org}/playlists.yml (args: organisation_slug, json|stdin)"
  task :add_playlist, [:organisation_slug, :json] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    payload = args[:json] && JSON.parse(args[:json])
    payload ||= JSON.parse($stdin.read)
    result = DataTools.add_or_update_playlist!(organisation_slug: org, attributes: payload)
    puts(result.to_json)
  end

  desc "Add a new event (playlist entry) under data/{org}/playlists.yml (args: organisation_slug, json|stdin)"
  task :add_event, [:organisation_slug, :json] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    payload = args[:json] && JSON.parse(args[:json])
    payload ||= JSON.parse($stdin.read)
    result = DataTools.add_event!(organisation_slug: org, attributes: payload)
    puts(result.to_json)
  end

  desc "Update an existing event by slug (args: organisation_slug, event_slug, json|stdin)"
  task :update_event, [:organisation_slug, :event_slug, :json] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    event = args[:event_slug]
    payload = args[:json] && JSON.parse(args[:json])
    payload ||= JSON.parse($stdin.read)
    result = DataTools.update_event!(organisation_slug: org, event_slug: event, attributes: payload)
    puts(result.to_json)
  end

  desc "Add or update a talk in data/{org}/{event}/videos.yml (args: organisation_slug, event_slug; body on stdin)"
  task :add_video, [:organisation_slug, :event_slug] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    event = args[:event_slug]
    payload = JSON.parse($stdin.read)
    result = DataTools.add_video!(organisation_slug: org, event_slug: event, attributes: payload)
    puts(result.to_json)
  end

  desc "Update a talk by selector (args: organisation_slug, event_slug; body on stdin with {selector:{...}, attributes:{...}})"
  task :update_video, [:organisation_slug, :event_slug] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    event = args[:event_slug]
    body = JSON.parse($stdin.read)
    result = DataTools.update_video!(organisation_slug: org, event_slug: event, selector: body["selector"], attributes: body["attributes"])
    puts(result.to_json)
  end

  desc "List talks of an event (args: organisation_slug, event_slug)"
  task :list_event_talks, [:organisation_slug, :event_slug] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    event = args[:event_slug]
    result = DataTools.list_event_talks(organisation_slug: org, event_slug: event)
    puts(result.to_json)
  end

  desc "List all talks of a speaker (args: speaker_name)"
  task :list_speaker_talks, [:speaker_name] => :environment do |_t, args|
    require "data_tools"
    result = DataTools.list_speaker_talks(speaker_name: args[:speaker_name])
    puts(result.to_json)
  end

  desc "Search speakers (args: query)"
  task :search_speakers, [:query] => :environment do |_t, args|
    require "data_tools"
    result = DataTools.search_speakers(query: args[:query])
    puts(result.to_json)
  end

  desc "Fetch speakers of event (args: organisation_slug, event_slug)"
  task :fetch_event_speakers, [:organisation_slug, :event_slug] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    event = args[:event_slug]
    result = DataTools.fetch_event_speakers(organisation_slug: org, event_slug: event)
    puts(result.to_json)
  end

  desc "Fetch speakers and talks for event (args: organisation_slug, event_slug)"
  task :fetch_event_speakers_and_talks, [:organisation_slug, :event_slug] => :environment do |_t, args|
    require "data_tools"
    org = args[:organisation_slug]
    event = args[:event_slug]
    result = DataTools.fetch_event_speakers_and_talks(organisation_slug: org, event_slug: event)
    puts(result.to_json)
  end

  desc "List all events (organisation slug, title, slug, dates)"
  task list_all_events: :environment do
    require "data_tools"
    puts DataTools.list_all_events.to_json
  end

  desc "Add or update a speaker in data/speakers.yml (args: json|stdin)"
  task :add_speaker, [:json] => :environment do |_t, args|
    require "data_tools"
    payload = args[:json] && JSON.parse(args[:json])
    payload ||= JSON.parse($stdin.read)
    result = DataTools.add_speaker!(payload)
    puts(result.to_json)
  end

  namespace :yt do
    desc "Fetch YouTube video metadata (args: video_id)"
    task :video, [:video_id] => :environment do |_t, args|
      require "yt"
      id = args[:video_id]
      abort("usage: bin/rails data:yt:video[VIDEO_ID]") if id.to_s.strip.empty?
      video = Yt::Video.new id: id
      result = {
        id: video.id,
        title: video.title,
        description: video.description,
        duration: video.duration,
        published_at: video.published_at&.to_s,
        channel_id: video.channel_id,
        thumbnails: video.thumbnail_url
      }
      puts result.to_json
    rescue => e
      abort(e.message)
    end

    desc "Fetch YouTube playlist items (args: playlist_id)"
    task :playlist, [:playlist_id] => :environment do |_t, args|
      require "yt"
      id = args[:playlist_id]
      abort("usage: bin/rails data:yt:playlist[PLAYLIST_ID]") if id.to_s.strip.empty?
      playlist = Yt::Playlist.new id: id
      items = playlist.playlist_items.map do |item|
        v = item.video
        {
          id: v.id,
          title: v.title,
          description: v.description,
          published_at: v.published_at&.to_s,
          channel_id: v.channel_id,
          thumbnail_xs: v.thumbnail_url,
          video_provider: "youtube",
          video_id: v.id
        }
      end
      puts items.to_json
    rescue => e
      abort(e.message)
    end
  end
end
