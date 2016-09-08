class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    @user = User.from_cas(request.env['omniauth.auth'])
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: 'from Princeton Central Authentication '\
                                                 'Service') if is_navigational_format?
    else
      redirect_to request.env['omniauth.origin'], alert: "Unauthorized user"
    end
  end
end