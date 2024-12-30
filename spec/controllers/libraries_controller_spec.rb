require 'rails_helper'

describe LibrariesController, type: :controller do
  let(:invalid_attributes) do
    FactoryBot.attributes_for(:library, label: nil)
  end

  describe 'GET #index' do
    render_views

    it 'assigns all libraries as @libraries' do
      library = FactoryBot.create(:library)
      get :index
      expect(assigns(:libraries)).to eq([library])
    end

    it 'libraries is active in navbar' do
      get :index
      expect(response.body.include?('<li class="active"><a href="/locations/libraries')).to be true
    end
  end

  describe 'GET #show' do
    it 'assigns the requested library as @library' do
      library = FactoryBot.create(:library)
      get :show, params: { id: library.code }
      expect(assigns(:library)).to eq(library)
    end
  end
end
