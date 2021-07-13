# frozen_string_literal: true

class HoldingLocationsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_holding_location, only: %i[show edit update destroy]

  # GET /holding_locations
  def index
    @holding_locations = HoldingLocation.order(:code)
  end

  # GET /holding_locations/1
  def show; end

  # GET /holding_locations/new
  def new
    @holding_location = HoldingLocation.new
  end

  # GET /holding_locations/1/edit
  def edit; end

  # POST /holding_locations
  def create
    @holding_location = HoldingLocation.new(holding_location_params)

    if @holding_location.save
      redirect_to @holding_location, notice: 'Holding location was successfully created.'
    else
      flash.now[:error] = @holding_location.errors.full_messages
      render :new
    end
  end

  # PATCH/PUT /holding_locations/1
  def update
    if @holding_location.update(holding_location_params)
      redirect_to @holding_location, notice: 'Holding location was successfully updated.'
    else
      flash.now[:error] = @holding_location.errors.full_messages
      render :edit
    end
  end

  # DELETE /holding_locations/1
  def destroy
    @holding_location.destroy
    redirect_to holding_locations_url, notice: 'Holding location was successfully destroyed.'
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_holding_location
      @holding_location = HoldingLocation.friendly.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def holding_location_params
      params.require(:holding_location).permit(:label, :code,
                                               :aeon_location, :recap_electronic_delivery_location, :open,
                                               :requestable, :always_requestable, :circulates, :locations_library_id,
                                               :holding_library_id, :locations_hours_location_id,
                                               delivery_location_ids: [])
    end
end
