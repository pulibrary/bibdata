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
        allow(controller).to receive(:redirect_to)

        controller.cas

        expect(controller).to have_received(:redirect_to).with('/', alert: 'Unauthorized user')
      end
    end
  end
end
