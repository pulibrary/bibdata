# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'pages/index', type: :view do
  it 'renders the header' do
    render
    expect(rendered).to match(%r{<h1>PUL Bibliographic Data Web Service</h1>})
  end

  it 'includes a section on the indexing process' do
    render
    expect(rendered).to match(%r{<h2>Indexing Process</h2>})
    expect(rendered).to match(%r{<th>Last dump indexed</th>})
    expect(rendered).to match(%r{<th>Timestamp</th>})
    expect(rendered).to match(%r{<th>In progress</th>})
  end

  context 'with index managers' do
    let!(:index_manager_one) { create(:index_manager, solr_collection: 'daily_indexing', last_dump_completed: create(:incremental_dump)) }
    let!(:index_manager_two) { create(:index_manager, solr_collection: 'rebuild_indexing', last_dump_completed: create(:full_dump)) }

    it 'includes the id of the last dump indexed' do
      render

      expect(rendered).to match(/#{index_manager_one.last_dump_completed_id}/)
      expect(rendered).to match(/#{index_manager_two.last_dump_completed_id}/)
      expect(rendered).to match(index_manager_one.solr_collection)
      expect(rendered).to have_link(index_manager_one.last_dump_completed_id.to_s, href: "http://test.host/dumps/#{index_manager_one.last_dump_completed_id}.json")
    end
  end
end
