class EventsController < ApplicationController
  before_action :set_event, only: [:show, :destroy] # , :edit, :update]
  before_action :authenticate_user!, only: [:destroy]

  respond_to :html, :json

  def index
    @events = Event.order('start asc')
    respond_with(@events)
  end

  def show
    respond_with(@event)
  end

  def destroy
    @event.destroy
    respond_with(@event)
  end

  private

    def set_event
      # nosemgrep
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:start, :finish, :error, :success)
    end
end
