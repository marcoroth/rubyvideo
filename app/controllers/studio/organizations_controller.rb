module Studio
  class OrganizationsController < BaseController
    before_action :set_organization, only: [:show, :edit, :update, :destroy]

    def index
      @organizations = Studio::YAMLService.read_organizations.sort_by { |org| org["name"] }
    end

    def show
      @events = Studio::YAMLService.list_organization_events(@organization["slug"])
      @playlists = Static::Playlist.all.to_a.select { |p| p.__file_path&.include?("#{@organization["slug"]}/") }
    end

    def new
      @organization = Organisation.new
    end

    def create
      @organization = Organisation.new(organization_params)

      if @organization.save
        # Add to organisations.yml
        orgs_data = Studio::YAMLService.read_organizations

        unless orgs_data.any? { |o| o["slug"] == @organization.slug }
          org_data = {
            "name" => @organization.name,
            "slug" => @organization.slug,
            "website" => @organization.website,
            "twitter" => @organization.twitter,
            "youtube_channel_name" => params[:youtube_channel_name],
            "youtube_channel_id" => params[:youtube_channel_id],
            "language" => params[:language] || "english",
            "kind" => @organization.kind,
            "frequency" => @organization.frequency,
            "meetup_id" => params[:meetup_id],
            "active" => true
          }.compact

          orgs_data << org_data
          Studio::YAMLService.write_organizations(orgs_data)
        end

        # Create organization directory
        FileUtils.mkdir_p(Studio::YAMLService::DATA_PATH.join(@organization.slug))

        # Initialize empty playlists.yml
        Studio::YAMLService.write_playlists(@organization.slug, [])

        redirect_to studio_organization_path(@organization), notice: "Organization created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # @organization is already set from YAML data in set_organization
    end

    def update
      previous_slug = params[:previous_slug]
      new_slug = params[:slug]

      begin
        # Update in organisations.yml only
        orgs_data = Studio::YAMLService.read_organizations
        org_entry = orgs_data.find { |o| o["slug"] == previous_slug }

        if org_entry
          # Update YAML data (always update, even if empty to allow clearing fields)
          org_entry["name"] = params[:name]
          org_entry["website"] = params[:website].present? ? params[:website] : nil
          org_entry["twitter"] = params[:twitter].present? ? params[:twitter] : nil
          org_entry["kind"] = params[:kind]
          org_entry["frequency"] = params[:frequency].present? ? params[:frequency] : nil
          org_entry["youtube_channel_name"] = params[:youtube_channel_name].present? ? params[:youtube_channel_name] : nil
          org_entry["youtube_channel_id"] = params[:youtube_channel_id].present? ? params[:youtube_channel_id] : nil
          org_entry["language"] = params[:language]
          org_entry["meetup_id"] = params[:meetup_id].present? ? params[:meetup_id] : nil

          # Handle slug change
          if new_slug && new_slug != previous_slug
            org_entry["slug"] = new_slug

            # Rename organization directory if it exists
            old_dir = Studio::YAMLService::DATA_PATH.join(previous_slug)
            new_dir = Studio::YAMLService::DATA_PATH.join(new_slug)

            if Dir.exist?(old_dir)
              FileUtils.mv(old_dir, new_dir)
            end
          end

          Studio::YAMLService.write_organizations(orgs_data)
        end

        # Redirect using the new slug if changed, otherwise use the old one
        final_slug = new_slug || previous_slug
        redirect_to studio_organization_path(id: final_slug), notice: "Organization updated successfully in YAML"
      rescue => e
        @organization = Studio::YAMLService.read_organizations.find { |o| o["slug"] == previous_slug }
        flash.now[:alert] = "Failed to update organization: #{e.message}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      slug = @organization["slug"]

      # Remove from organisations.yml
      orgs_data = Studio::YAMLService.read_organizations
      orgs_data.reject! { |o| o["slug"] == slug }
      Studio::YAMLService.write_organizations(orgs_data)

      redirect_to studio_organizations_path, notice: "Organization deleted successfully from YAML"
    end

    private

    def set_organization
      @organization = Studio::YAMLService.read_organizations.find { |o| o["slug"] == params[:id] }
      redirect_to studio_organizations_path, alert: "Organization not found" unless @organization
    end

    def organization_params
      params.require(:organisation).permit(:name, :slug, :previous_slug, :website, :twitter, :kind, :frequency)
    end
  end
end
