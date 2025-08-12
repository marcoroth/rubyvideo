module Studio
  class EventsController < BaseController
    before_action :set_organization_slug
    before_action :set_event_data, only: [:show, :edit, :update, :destroy, :fetch_videos]

    def index
      if @organization_slug
        @events = Studio::YAMLService.list_organization_events(@organization_slug)
        @organization_name = Studio::YAMLService.read_organizations.find { |o| o["slug"] == @organization_slug }&.dig("name")
      else
        @events = []
        Studio::YAMLService.read_organizations.each do |org|
          events = Studio::YAMLService.list_organization_events(org["slug"])
          @events += events.map { |event_slug|
            {"slug" => event_slug, "organisation_slug" => org["slug"], "organisation_name" => org["name"]}
          }
        end
      end
    end

    def show
      @videos = Studio::YAMLService.read_event_videos(@organization_slug, @event_slug)
      @sponsors = Studio::YAMLService.read_event_sponsors(@organization_slug, @event_slug)
      @playlist = Studio::YAMLService.read_playlists(@organization_slug).find { |p| p["slug"] == @event_slug } || {}
    end

    def new
      @event = {}
      @organizations = Studio::YAMLService.read_organizations

      if params[:organization_id].present?
        @preselected_organization = params[:organization_id]
      end
    end

    def create
      event_data = event_params.to_h
      organization_slug = event_data.delete("organisation_slug")
      event_slug = event_data["slug"]

      if event_slug.blank?
        event_slug = event_data["name"].parameterize
        event_data["slug"] = event_slug
      end

      begin
        Studio::YAMLService.create_event_directory(organization_slug, event_slug)

        Studio::YAMLService.write_event_videos(organization_slug, event_slug, [])

        playlists = Studio::YAMLService.read_playlists(organization_slug)

        unless playlists.any? { |p| p["slug"] == event_slug }
          playlist_data = {
            "title" => event_data["name"],
            "slug" => event_slug,
            "published_at" => event_data["date"],
            "description" => "",
            "website_url" => event_data["website"],
            "playlist_id" => params[:playlist_id].presence
          }.compact

          playlists << playlist_data
          Studio::YAMLService.write_playlists(organization_slug, playlists)
        end

        redirect_to studio_event_path(id: event_slug, organization_id: organization_slug), notice: "Event created successfully"
      rescue => e
        @event = event_data
        @organizations = Studio::YAMLService.read_organizations
        flash.now[:alert] = "Failed to create event: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @playlists = Studio::YAMLService.read_playlists(@organization_slug)
      @playlist = @playlists.find { |p| p["slug"] == @event_slug } || {}
      @organizations = Studio::YAMLService.read_organizations
    end

    def update
      event_data = event_params.to_h
      new_slug = event_data["slug"]
      previous_slug = params[:previous_slug]

      # Update playlist data
      playlists = Studio::YAMLService.read_playlists(@organization_slug)
      playlist = playlists.find { |p| p["slug"] == previous_slug }

      if playlist
        playlist["title"] = event_data["name"] if event_data["name"].present?
        playlist["website_url"] = event_data["website"] if event_data["website"].present?
        playlist["playlist_id"] = params[:playlist_id] if params[:playlist_id].present?

        if new_slug != previous_slug
          playlist["slug"] = new_slug

          old_dir = Studio::YAMLService::DATA_PATH.join(@organization_slug, previous_slug)
          new_dir = Studio::YAMLService::DATA_PATH.join(@organization_slug, new_slug)

          if Dir.exist?(old_dir)
            FileUtils.mv(old_dir, new_dir)
          end
        end

        Studio::YAMLService.write_playlists(@organization_slug, playlists)
      end

      final_slug = new_slug.present? ? new_slug : @event_slug

      redirect_to studio_event_path(id: final_slug, organization_id: @organization_slug), notice: "Event updated successfully"
    rescue => e
      @playlists = Studio::YAMLService.read_playlists(@organization_slug)
      @playlist = @playlists.find { |p| p["slug"] == @event_slug } || {}
      @organizations = Studio::YAMLService.read_organizations

      flash.now[:alert] = "Failed to update event: #{e.message}"

      render :edit, status: :unprocessable_entity
    end

    def destroy
      playlists = Studio::YAMLService.read_playlists(@organization_slug)
      playlists.reject! { |p| p["slug"] == @event_slug }
      Studio::YAMLService.write_playlists(@organization_slug, playlists)

      # Optionally remove event directory
      # FileUtils.rm_rf(Studio::YAMLService::DATA_PATH.join(@organization_slug, @event_slug))

      redirect_to studio_events_path, notice: "Event deleted successfully"
    rescue => e
      redirect_to studio_event_path(id: @event_slug, organization_id: @organization_slug), alert: "Failed to delete event: #{e.message}"
    end

    def fetch_videos
      playlist_id = params[:playlist_id]

      if playlist_id.blank?
        redirect_to studio_event_path(id: @event_slug, organization_id: @organization_slug), alert: "Please provide a YouTube playlist ID"
        return
      end

      begin
        event_name = @playlist["title"] || @event_slug.humanize

        videos = YouTube::PlaylistItems.new.all(playlist_id: playlist_id)

        video_data = videos.map do |video|
          {
            "title" => video.title,
            "raw_title" => video.title,
            "description" => video.description,
            "date" => video.published_at,
            "event_name" => event_name,
            "published_at" => video.published_at,
            "video_id" => video.video_id,
            "video_provider" => "youtube",
            "thumbnail_xs" => video.thumbnail_xs,
            "thumbnail_sm" => video.thumbnail_sm,
            "thumbnail_md" => video.thumbnail_md,
            "thumbnail_lg" => video.thumbnail_lg,
            "thumbnail_xl" => video.thumbnail_xl,
            "language" => "english"
          }
        end

        Studio::YAMLService.write_event_videos(@organization_slug, @event_slug, video_data)

        redirect_to studio_event_path(id: @event_slug, organization_id: @organization_slug), notice: "Fetched #{videos.count} videos from YouTube"
      rescue => e
        redirect_to studio_event_path(id: @event_slug, organization_id: @organization_slug), alert: "Failed to fetch videos: #{e.message}"
      end
    end

    private

    def set_organization_slug
      @organization_slug = params[:organization_id]
    end

    def set_event_data
      @event_slug = params[:id]
      @organization_slug = params[:organization_id]

      unless @organization_slug
        Studio::YAMLService.read_organizations.each do |org|
          playlists = Studio::YAMLService.read_playlists(org["slug"])

          if playlists.any? { |p| p["slug"] == @event_slug }
            @organization_slug = org["slug"]
            break
          end
        end
      end

      if @organization_slug
        playlists = Studio::YAMLService.read_playlists(@organization_slug)
        @playlist = playlists.find { |p| p["slug"] == @event_slug } || {}
        @event = @playlist
      else
        raise "Event '#{@event_slug}' not found in any organization"
      end
    end

    def event_params
      params.permit(:name, :slug, :previous_slug, :date, :end_date, :location, :website, :description, :cfp_link, :cfp_open_date, :cfp_close_date, :banner_background, :featured_background, :featured_color, :organisation_slug)
    end
  end
end
