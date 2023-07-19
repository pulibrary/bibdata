# frozen_string_literal: true

class HoldingLocationsController < ApplicationController
  before_action :set_holding_location, only: %i[show]

  # GET /holding_locations
  def index
    @holding_locations = HoldingLocation.order(:code)
  end

  # GET /holding_locations/1
  def show; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_holding_location
      # nosemgrep
      @holding_location = HoldingLocation.friendly.find(params[:id])
    end
end
