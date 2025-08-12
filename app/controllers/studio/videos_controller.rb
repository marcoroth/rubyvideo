module Studio
  class VideosController < BaseController
    before_action :set_event_data
    before_action :set_video, only: [:show, :edit, :update, :destroy]

    def index
      @videos = Studio::YAMLService.read_event_videos(@organization_slug, @event_slug)
    end

    def show
      @youtube_embed_url = "https://www.youtube.com/embed/#{@video["video_id"]}" if @video["video_provider"] == "youtube"
    end

    def new
      @video = {
        "event_name" => @event["title"] || @event["name"],
        "date" => Date.current.strftime("%Y-%m-%d"),
        "language" => "english",
        "video_provider" => "youtube"
      }
    end

    def create
      video_data = video_params.to_h

      # Add default fields
      video_data["event_name"] = @event["title"] || @event["name"]
      video_data["published_at"] ||= Date.current.strftime("%Y-%m-%d")

      # Read existing videos
      videos = Studio::YAMLService.read_event_videos(@organization_slug, @event_slug)

      # Add new video
      videos << video_data

      # Write back to file
      Studio::YAMLService.write_event_videos(@organization_slug, @event_slug, videos)

      redirect_to studio_event_videos_path(event_id: @event_slug), notice: "Video added successfully"
    end

    def edit
      # Video is already set by set_video
    end

    def update
      videos = Studio::YAMLService.read_event_videos(@organization_slug, @event_slug)

      # Find and update the video
      video_index = params[:index].to_i
      if videos[video_index]
        videos[video_index].merge!(video_params.to_h)
        Studio::YAMLService.write_event_videos(@organization_slug, @event_slug, videos)
        redirect_to studio_event_videos_path(event_id: @event_slug), notice: "Video updated successfully"
      else
        redirect_to studio_event_videos_path(event_id: @event_slug), alert: "Video not found"
      end
    end

    def destroy
      videos = Studio::YAMLService.read_event_videos(@organization_slug, @event_slug)

      # Remove the video
      video_index = params[:index].to_i
      if videos[video_index]
        videos.delete_at(video_index)
        Studio::YAMLService.write_event_videos(@organization_slug, @event_slug, videos)
        redirect_to studio_event_videos_path(event_id: @event_slug), notice: "Video removed successfully"
      else
        redirect_to studio_event_videos_path(event_id: @event_slug), alert: "Video not found"
      end
    end

    private

    def set_event_data
      @event_slug = params[:event_id]

      # Find the organization that contains this event
      Studio::YAMLService.read_organizations.each do |org|
        playlists = Studio::YAMLService.read_playlists(org["slug"])
        if playlists.any? { |p| p["slug"] == @event_slug }
          @organization_slug = org["slug"]
          break
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

    def set_video
      videos = Studio::YAMLService.read_event_videos(@organization_slug, @event_slug)
      @video = videos[params[:id].to_i] || {}
    end

    def video_params
      params.require(:video).permit(
        :title, :raw_title, :description, :date, :published_at, :announced_at,
        :video_id, :video_provider, :language, :track, :slides_url,
        :thumbnail_xs, :thumbnail_sm, :thumbnail_md, :thumbnail_lg, :thumbnail_xl,
        :start_cue, :end_cue, :thumbnail_cue,
        speakers: []
      )
    end
  end
end
