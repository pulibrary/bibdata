require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { described_class.new(uid:, username:, email:, password:, provider:) }
  let(:uid) { 'user123' }
  let(:username) { 'user123' }
  let(:email) { 'user123@localhost.localdomain' }
  let(:password) { 'secret' }
  let(:provider) { 'cas' }

  describe '#catalog_admin?' do
    it 'identifies non-administrator users' do
      expect(user.catalog_admin?).to be false
    end

    context 'with an administrator' do
      let(:uid) { 'admin123' }

      it 'identifies administrator users using the UID' do
        expect(user.catalog_admin?).to be true
      end
    end
  end

  describe ".from_cas" do
    let(:access_token) { OmniAuth::AuthHash.new(provider:, uid:) }

    it "finds or creates user in the database" do
      expect { described_class.from_cas(access_token) }.to change(described_class, :count).by(1)
    end
  end
end
