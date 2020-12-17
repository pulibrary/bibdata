class CampusAccessExceptionsController < ApplicationController
  before_action :protect

  def new
    @campus_access_exception = CampusAccessException.new
  end

  def create
    uploaded_io = params[:exception_file]
    file_name = Rails.root.join('tmp', uploaded_io.original_filename)
    File.open(file_name, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    @campus_access_filename = "#{ENV['CAMPUS_ACCESS_DIRECTORY']}/additional_campus_access.csv"
    campus_exceptions = CampusAccessException.new(@campus_access_filename)
    campus_exceptions.process_new_exceptions(file_name)
    @invalid_exceptions = campus_exceptions.invalid_exceptions
    campus_exceptions.export_to_file(@campus_access_filename)
    render :new
  end

  private

    # Ensure that the client is authenticated and the user is a catalog administrator
    def protect
      if user_signed_in?
        render plain: "You are unauthorized", status: 403 unless current_user.catalog_admin?
      else
        store_location_for(:user, new_campus_access_exception_path)
        redirect_to user_cas_omniauth_authorize_path
      end
    end
end
