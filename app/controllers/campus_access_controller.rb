class CampusAccessController < ApplicationController
  def index
    respond_to do |format|
      format.csv { send_data CampusAccess.to_csv, filename: "campus_access.csv" }
    end
  end
end
