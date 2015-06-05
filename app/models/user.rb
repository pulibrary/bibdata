class User < ActiveRecord::Base

  devise :database_authenticatable,
         :rememberable, :trackable, :validatable,
         :omniauthable

  def self.find_for_cas(access_token, signed_in_resource=nil)
    logger.debug "#{access_token.inspect}"
  
    @user = User.where(provider: access_token.provider, uid: access_token.uid).first_or_create do |user|
      user.uid = access_token.uid
      user.username = access_token.uid
      user.email = "#{access_token.uid}@princeton.edu" 
      user.password = Devise.friendly_token[0,20]
      user.provider = access_token.provider
    end
    @user
  end
end
