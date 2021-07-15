# frozen_string_literal: true

class HoursLocationsController < ApplicationController
  before_action :set_hours_location, only: %i[show]

  # GET /hours_locations
  def index
    @hours_locations = HoursLocation.all
  end

  # GET /hours_locations/1
  def show; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_hours_location
      @hours_location = HoursLocation.friendly.find(params[:id])
    end
end
