class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include ApplicationHelper

  def after_sign_out_path_for(_resource_or_scope)
    request.referer
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
    elsif exception.is_a?(Net::ReadTimeout)
      Rails.logger.error "HTTP 504. #{message} #{exception}"
      head :gateway_timeout
    else
      Rails.logger.error "HTTP 500. #{message} #{exception}"
      head :internal_server_error
    end
  end

  private

    def verify_admin!
      authenticate_user!
      head :forbidden unless current_user.catalog_admin?
    end
end
