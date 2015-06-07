class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    find_user('CAS')
  end

  def find_user(auth_type)
    find_method = "find_for_#{auth_type.downcase}".to_sym
    $stderr.puts "#{auth_type} :: #{current_user.inspect}"
    @user = User.send(find_method,request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in @user
      redirect_to request.env['omniauth.origin']
    else
      session["devise.#{auth_type.downcase}_data"] = request.env["omniauth.auth"]
      redirect_to request.env['omniauth.origin'], alert: "Unauthorized user"
    end
  end
  protected :find_user
end