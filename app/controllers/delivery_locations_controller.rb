# frozen_string_literal: true

module Locations
  class DeliveryLocationsController < ApplicationController
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

    # GET /delivery_locations/new
    def new
      @delivery_location = DeliveryLocation.new
    end

    # GET /delivery_locations/1/edit
    def edit; end

    # POST /delivery_locations
    def create
      @delivery_location = DeliveryLocation.new(delivery_location_params)

      if @delivery_location.save
        redirect_to @delivery_location, notice: 'Delivery location was successfully created.'
      else
        flash.now[:error] = @delivery_location.errors.full_messages
        render :new
      end
    end

    # PATCH/PUT /delivery_locations/1
    def update
      if @delivery_location.update(delivery_location_params)
        redirect_to @delivery_location, notice: 'Delivery location was successfully updated.'
      else
        flash.now[:error] = @delivery_location.errors.full_messages
        render :edit
      end
    end

    # DELETE /delivery_locations/1
    def destroy
      @delivery_location.destroy
      redirect_to delivery_locations_url, notice: 'Delivery location was successfully destroyed.'
    end

    private

      # Use callbacks to share common setup or constraints between actions.
      def set_delivery_location
        @delivery_location = DeliveryLocation.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def delivery_location_params
        params.require(:delivery_location).permit(:label, :address, :phone_number, :contact_email, :gfa_pickup, :staff_only, :pickup_location, :digital_location, :locations_library_id, :locations_holding_location_id)
      end
  end
end
