module Studio
  class BaseController < ApplicationController
    before_action :require_development_environment!
    skip_before_action :authenticate_user!

    private

    def require_development_environment!
      unless Rails.env.development?
        redirect_to root_path, alert: "Studio is only available in development environment"
      end
    end
  end
end
