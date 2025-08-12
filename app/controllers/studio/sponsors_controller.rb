module Studio
  class SponsorsController < BaseController
    def index
      @events = Event.includes(:organisation).where(kind: "conference").order(date: :desc).limit(20)
      @filter = params[:filter] || "all"

      case @filter
      when "with_sponsors"
        @events = @events.select { |event| sponsors_exist?(event) }
      when "without_sponsors"
        @events = @events.reject { |event| sponsors_exist?(event) }
      end
    end

    def create
      event = Event.find(params[:event_id])
      temp_file_path = params[:temp_file] || session[:temp_sponsors_file]

      if temp_file_path.present? && File.exist?(temp_file_path)
        # Move temp file to final location
        final_path = Studio::YAMLService::DATA_PATH.join(
          event.organisation.slug,
          event.slug,
          "sponsors.yml"
        )

        # Ensure directory exists
        FileUtils.mkdir_p(final_path.dirname)

        # Move temp file to final location
        FileUtils.mv(temp_file_path, final_path)

        # Clear session temp file
        session.delete(:temp_sponsors_file)

        redirect_to studio_sponsors_path, notice: "Sponsors saved successfully for #{event.name}"
      else
        # Fallback to old behavior if no temp file
        save_path = Studio::YAMLService::DATA_PATH.join(
          event.organisation.slug,
          event.slug,
          "sponsors.yml"
        )

        sponsor_url = params[:sponsor_url]
        base_url = params[:base_url]
        html_content = params[:html_content]

        begin
          downloader = DownloadSponsors.new

          if sponsor_url.present?
            downloader.download_sponsors(sponsors_url: sponsor_url, save_file: save_path)
          elsif base_url.present?
            downloader.download_sponsors(base_url: base_url, save_file: save_path)
          elsif html_content.present?
            downloader.download_sponsors(html: html_content, save_file: save_path)
          else
            redirect_to studio_sponsors_path, alert: "Please provide a URL or HTML content"
            return
          end

          redirect_to studio_sponsors_path, notice: "Sponsors downloaded successfully for #{event.name}"
        rescue => e
          redirect_to studio_sponsors_path, alert: "Failed to download sponsors: #{e.message}"
        end
      end
    end

    def fetch
      begin
        event = Event.find(params[:event_id])
        sponsor_url = params[:sponsor_url]
        base_url = params[:base_url] || event.website

        Rails.logger.info "Fetching sponsors for event #{event.name} (ID: #{event.id})"
        Rails.logger.info "Sponsor URL: #{sponsor_url}"
        Rails.logger.info "Base URL: #{base_url}"

        if sponsor_url.blank? && base_url.blank?
          render html: "<div class='card-body'><div class='alert alert-warning'>Please provide a URL</div></div>".html_safe
          return
        end

        downloader = DownloadSponsors.new
        Rails.logger.info "DownloadSponsors initialized successfully"

        # Create a temporary file to preview
        temp_file = Rails.root.join("tmp", "preview_sponsors_#{event.id}_#{Time.current.to_i}.yml")
        FileUtils.mkdir_p(Rails.root.join("tmp"))

        if sponsor_url.present?
          Rails.logger.info "Downloading sponsors from direct URL: #{sponsor_url}"
          downloader.download_sponsors(sponsors_url: sponsor_url, save_file: temp_file)
        elsif base_url.present?
          Rails.logger.info "Downloading sponsors from base URL: #{base_url}"
          downloader.download_sponsors(base_url: base_url, save_file: temp_file)
        end

        if File.exist?(temp_file)
          @sponsors = YAML.load_file(temp_file)
          @event = event
          Rails.logger.info "Successfully loaded sponsors from temp file"

          # Keep temp file for potential save action - store temp file path in session
          session[:temp_sponsors_file] = temp_file.to_s

          render partial: "studio/sponsors/preview", locals: {sponsors: @sponsors, event: @event, temp_file: temp_file.to_s}
        else
          render html: "<div class='card-body'><div class='alert alert-error'>No sponsors file was created</div></div>".html_safe
        end
      rescue => e
        Rails.logger.error "Failed to fetch sponsors: #{e.class.name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render html: "<div class='card-body'><div class='alert alert-error'>Failed to fetch sponsors: #{e.class.name}: #{e.message}</div></div>".html_safe
      end
    end

    private

    def sponsors_exist?(event)
      File.exist?(Studio::YAMLService::DATA_PATH.join(event.organisation.slug, event.slug, "sponsors.yml"))
    end
  end
end
