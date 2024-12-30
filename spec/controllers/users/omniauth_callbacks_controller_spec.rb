require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController do
  describe '#cas' do
    before do
      allow(User).to receive(:from_cas).and_return(user)
    end

    context 'failed authentication' do
      let(:user) { instance_double(User, { persisted?: false }) }

      it 'alerts the user on failure' do
        controller = described_class.new
        controller.request = ActionDispatch::TestRequest.new('omniauth.origin' => '/')
        controller.should_receive(:redirect_to).with('/', alert: 'Unauthorized user')
        controller.cas
      end
    end
  end
end
