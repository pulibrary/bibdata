# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    flash[:alert] = "<strong><a href='https://fed.princeton.edu/cas/logout'>Sign out from CAS</a></strong>"
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    yield if block_given?
    respond_to_on_destroy
  end
end
