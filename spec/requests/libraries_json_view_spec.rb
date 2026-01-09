# frozen_string_literal: true

require 'rails_helper'

describe 'Library json view', type: :request do
  it 'Renders the json template' do
    get libraries_path, params: { format: :json }
    expect(response).to render_template(:index)
    expect(response.content_type).to eq 'application/json; charset=utf-8'
  end

  describe 'the response body' do
    it "/libraries looks as we'd expect, sorted by order" do
      create_list(:library, 2)
      expected = []
      Library.all.find_each do |library|
        attrs = {
          label: library.label,
          code: library.code,
          order: library.order,
          path: library_path(library, format: :json)
        }
        expected << attrs
      end
      sorted = expected.sort_by { |l| [l[:order], l[:label]] }
      get libraries_path, params: { format: :json }
      expect(response.body).to eq sorted.to_json
    end

    it "/libraries/{code} looks as we'd expect" do
      library = create(:library)
      expected = {
        label: library.label,
        code: library.code,
        order: library.order
      }
      get library_path(library), params: { format: :json }
      expect(response.body).to eq expected.to_json
    end
  end
end
