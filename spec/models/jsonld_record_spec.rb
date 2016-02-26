require 'rails_helper'

RSpec.describe JSONLDRecord, :type => :model do
  let(:solr_doc) {{
    'title_citation_display'     => ['This is the Title'],
    'summary_note_display'       => ['This is a note about it.'],
    'pub_date_display'           => ['1970'],
    'language_facet'             => ['English', 'Spanish'],
    'language_code_s'            => ['eng'],
    'author_display'             => ['Author, Alice'],
    'related_name_json_1display' => ['{"Translators":["Translator, Bob", "Translator, Carol"],"Donor":["Translator, Carol"]}']
  }}
  subject { described_class.new solr_doc }

  it 'produces json+ld' do
    json_ld = {
      title: {'@value':'This is the Title', '@language':'eng'},
      description: 'This is a note about it.',
      creator: 'Author, Alice',
      date: '1970',
      language: ['English', 'Spanish'],
      language_code: 'eng',
      contributor: ['Translator, Bob', 'Translator, Carol']
    }
    expect(subject.to_h.symbolize_keys).to eq(json_ld)
  end
end
