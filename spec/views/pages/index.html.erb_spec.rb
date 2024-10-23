# frozen_string_literal: true
require "rails_helper"

RSpec.describe "pages/index", type: :view do
  it 'renders the header' do
    render
    expect(rendered).to match(/<h1>PUL Bibliographic Data Web Service<\/h1>/)
  end
  it 'includes a section on the indexing process' do
    render
    expect(rendered).to match(/<h2>Indexing Process<\/h2>/)
    expect(rendered).to match(/<th>Last dump indexed<\/th>/)
    expect(rendered).to match(/<th>Timestamp<\/th>/)
    expect(rendered).to match(/<th>In progress<\/th>/)
  end
  context 'with index managers' do
    let!(:index_manager1) { FactoryBot.create(:index_manager, solr_collection: 'daily_indexing', last_dump_completed: FactoryBot.create(:incremental_dump)) }
    let!(:index_manager2) { FactoryBot.create(:index_manager, solr_collection: 'rebuild_indexing', last_dump_completed: FactoryBot.create(:full_dump)) }

    it 'includes the id of the last dump indexed' do
      render

      expect(rendered).to match(/#{index_manager1.last_dump_completed_id}/)
      expect(rendered).to match(/#{index_manager2.last_dump_completed_id}/)
      expect(rendered).to match(index_manager1.solr_collection)
      expect(rendered).to have_link(index_manager1.last_dump_completed_id.to_s, href: "http://test.host/dumps/#{index_manager1.last_dump_completed_id}.json")
    end
  end
end
