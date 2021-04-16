class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper Locations::ApplicationHelper
  include ApplicationHelper

  def after_sign_out_path_for(_resource_or_scope)
    request.referrer
  end

  def handle_alma_exception(exception:, message:)
    if exception.is_a?(Alma::PerSecondThresholdError)
      Rails.logger.error "HTTP 429. #{message} #{exception}"
      head :too_many_requests
    elsif exception.is_a?(Alma::NotFoundError)
      Rails.logger.error "HTTP 404. #{message} #{exception}"
      head :not_found
    elsif exception.is_a?(Alma::StandardError)
      Rails.logger.error "HTTP 400. #{message} #{exception}"
      head :bad_request
    else
      Rails.logger.error "HTTP 500. #{message} #{exception}"
      head :internal_server_error
    end
  end
end
