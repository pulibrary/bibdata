# frozen_string_literal: true

class HoursLocationsController < ApplicationController
  before_action :set_hours_location, only: %i[show edit update destroy]

  # GET /hours_locations
  def index
    @hours_locations = HoursLocation.all
  end

  # GET /hours_locations/1
  def show; end

  # GET /hours_locations/new
  def new
    @hours_location = HoursLocation.new
  end

  # GET /hours_locations/1/edit
  def edit; end

  # POST /hours_locations
  def create
    @hours_location = HoursLocation.new(hours_location_params)

    if @hours_location.save
      redirect_to @hours_location, notice: 'Hours location was successfully created.'
    else
      flash.now[:error] = @hours_location.errors.full_messages
      render :new
    end
  end

  # PATCH/PUT /hours_locations/1
  def update
    if @hours_location.update(hours_location_params)
      redirect_to @hours_location, notice: 'Hours location was successfully updated.'
    else
      flash.now[:error] = @hours_location.errors.full_messages
      render :edit
    end
  end

  # DELETE /hours_locations/1
  def destroy
    @hours_location.destroy
    redirect_to hours_locations_url, notice: 'Hours location was successfully destroyed.'
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_hours_location
      @hours_location = HoursLocation.friendly.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def hours_location_params
      params.require(:hours_location).permit(:code, :label)
    end
end
