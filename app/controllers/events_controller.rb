class EventsController < ApplicationController
  include Pagy::Backend
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_event, only: %i[show edit update]

  # GET /events
  def index
    @events = Event.all.order(date: :desc)
  end

  # GET /events/1
  def show
    @from_talk_id = session[:from_talk_id]
    session[:from_talk_id] = nil
    @pagy, @talks = pagy(@event.talks.order(date: :desc).includes(:speakers, :event), items: 9)
  end

  # GET /events/1/edit
  def edit
  end

  # PATCH/PUT /events/1
  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find_by(slug: params[:slug])
  end

  # Only allow a list of trusted parameters through.
  def event_params
    params.require(:event).permit(:name, :description, :website, :kind, :frequency)
  end
end
