module Studio
  class DashboardController < BaseController
    def index
      @recent_events = Event.order(updated_at: :desc).limit(10)
      @organizations = Organisation.order(:name)
      @total_events = Event.count
      @total_talks = Talk.count
      @total_speakers = Speaker.count
    end
  end
end
