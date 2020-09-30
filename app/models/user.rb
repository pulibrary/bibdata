class User < ActiveRecord::Base
  devise :database_authenticatable,
         :rememberable, :trackable, :validatable,
         :omniauthable

  def self.from_cas(access_token)
    User.where(provider: access_token.provider, uid: access_token.uid).first_or_create do |user|
      user.uid = access_token.uid
      user.username = access_token.uid
      user.email = "#{access_token.uid}@princeton.edu"
      user.password = SecureRandom.urlsafe_base64
      user.provider = access_token.provider
    end
  end

  # Determines whether or not a given user is a catalog administrator
  # @return [TrueClass, FalseClass]
  def catalog_admin?
    netids = Rails.application.config.authz
    netids.include? uid
  end
end
