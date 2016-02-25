require 'rails_helper'

RSpec.describe IIIFRecord, :type => :model do
  let(:solr_doc) {{ "foo" => ['bar'] }}
  let(:solr_doc) {{
    "title_citation_display"     => ['This is the Title'],
    "summary_note_display"       => ['This is a note about it.'],
    "pub_date_display"           => ['1970'],
    "language_facet"             => ['English', 'Spanish'],
    "language_code_s"            => ['eng'],
    "author_display"             => ['Author, Alice'],
    "related_name_json_1display" => ['{"Translators":["Translator, Bob", "Translator, Carol"],"Donor":["Translator, Carol"]}']
  }}
  subject { described_class.new solr_doc }

  it 'produces iiif json' do
    iiif_json = {
      label: 'This is the Title',
      description: 'This is a note about it.',
      metadata: [
        { label: 'creator', value: 'Author, Alice' },
        { label: 'date', value: '1970' },
        { label: 'language', value: ['English', 'Spanish'] },
        { label: 'language_code', value: 'eng' },
        { label: 'contributor', value: ['Translator, Bob', 'Translator, Carol'] }
      ]
    }
    expect(subject.to_json).to eq(iiif_json)
  end
end
