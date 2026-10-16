require 'rails_helper'

describe LibrariesController, type: :controller do
  let(:invalid_attributes) do
    attributes_for(:library, label: nil)
  end

  describe 'GET #index' do
    render_views

    it 'assigns all libraries as @libraries' do
      library = create(:library)
      get :index
      expect(assigns(:libraries)).to eq([library])
    end

    it 'libraries is active in navbar' do
      get :index

      nav_link = response.parsed_body
                         .at_css('li.nav-item.active a[href^="/locations/libraries"]')

      expect(nav_link).not_to be_nil
    end
  end

  describe 'GET #show' do
    it 'assigns the requested library as @library' do
      library = create(:library)
      get :show, params: { id: library.code }
      expect(assigns(:library)).to eq(library)
    end
  end
end
