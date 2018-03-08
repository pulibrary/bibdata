class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper Locations::ApplicationHelper
  include ApplicationHelper

  def after_sign_out_path_for(_resource_or_scope)
    request.referrer
  end
end
