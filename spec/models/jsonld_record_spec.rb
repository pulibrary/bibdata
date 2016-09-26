require 'rails_helper'

RSpec.describe JSONLDRecord, :type => :model do
  context 'with date ranges' do
    let(:solr_doc) {{
      'title_citation_display'     => ['This is the Title'],
      'summary_note_display'       => ['This is a note about it.'],
      'description_display'        => ['340 p., ill., 24 cm'],
      'pub_date_display'           => ['1970'],
      'pub_date_start_sort'        => ['1970'],
      'pub_date_end_sort'          => ['1972'],
      'pub_created_display'        => ['New York : Farrar, Straus Giroux, 1970.'],
      'call_number_display'        => ['ND623.C3 M8'],
      'language_code_s'            => ['eng', 'spa', 'chi'],
      'author_display'             => ['Author, Alice'],
      'related_name_json_1display' => ['{"Translators":["Translator, Bob", "Translator, Carol"],"Former owner":["Translator, Carol"],"Related name":["Contributor, Donald"]}']
    }}
    subject { described_class.new solr_doc }

    it 'produces json+ld' do
      json_ld = {
        title: {'@value':'This is the Title', '@language':'eng'},
        description: 'This is a note about it.',
        extent: '340 p., ill., 24 cm',
        creator: 'Author, Alice',
        date: '1970-1972',
        created: '1970-01-01T00:00:00Z/1972-12-31T23:59:59Z',
        call_number: 'ND623.C3 M8',
        language: ['eng', 'spa', 'zho'],
        publisher: 'New York : Farrar, Straus Giroux, 1970.',
        contributor: ['Contributor, Donald'],
        former_owner: ['Translator, Carol'],
        translator: ['Translator, Bob', 'Translator, Carol']
      }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end

  context 'with multiple roles' do
    let(:solr_doc) {{
      'title_citation_display'     => ['This is the Title'],
      'language_facet'             => ['English'],
      'language_code_s'            => ['eng'],
      'pub_date_start_sort'        => ['1970'],
      'author_display'             => ['Composer, Carol'],
      'marc_relator_display'       => ['Composer']
    }}
    subject { described_class.new solr_doc }

    it 'maps the creator to dc:creator and the more specific role' do
      json_ld = {
        title: {'@value':'This is the Title', '@language': 'eng'},
        date: '1970',
        created: '1970-01-01T00:00:00Z',
        language: 'eng',
        creator: 'Composer, Carol',
        composer: 'Composer, Carol'
      }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end
end
