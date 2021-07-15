# frozen_string_literal: true

class DeliveryLocationsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_delivery_location, only: %i[show edit update destroy]

  # GET /delivery_locations
  def index
    @delivery_locations = DeliveryLocation.all
  end

  # GET /digital_locations
  def digital_locations
    @delivery_locations = DeliveryLocation.select(&:digital_location?)
    render :index
  end

  # GET /delivery_locations/1
  def show; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_delivery_location
      @delivery_location = DeliveryLocation.find(params[:id])
    end
end
