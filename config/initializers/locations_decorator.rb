module Locations

	LibrariesController.class_eval do
	  before_action :authenticate_user!, 
	  only: [:new, :create, :edit, :update, :destroy]
	end

	HoursLocationsController.class_eval do
	  before_action :authenticate_user!, 
	  only: [:new, :create, :edit, :update, :destroy]
	end

	DeliveryLocationsController.class_eval do
	  before_action :authenticate_user!, 
	  only: [:new, :create, :edit, :update, :destroy]
	end

	HoldingLocationsController.class_eval do
	  before_action :authenticate_user!, 
	  only: [:new, :create, :edit, :update, :destroy]
	end			
end