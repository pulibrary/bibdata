require 'rails_helper'

RSpec.describe JSONLDRecord, :type => :model do
  context 'with date ranges' do
    let(:solr_doc) {{
      'title_citation_display'     => ['This is the Title'],
      'title_sort'                 => ['this is the title'],
      'summary_note_display'       => ['This is a note about it.'],
      'notes_display'              => ['This is another note.'],
      'description_display'        => ['340 p., ill., 24 cm'],
      'pub_date_display'           => ['1970'],
      'pub_date_start_sort'        => ['1970'],
      'pub_date_end_sort'          => ['1972'],
      'pub_created_display'        => ['New York : Farrar, Straus Giroux, 1970.'],
      'call_number_display'        => ['ND623.C3 M8'],
      'genre_facet'                => ['Biography'],
      'language_code_s'            => ['eng', 'spa', 'chi'],
      'author_display'             => ['Author, Alice'],
      'electronic_access_1display' => ['{"http://arks.princeton.edu/ark:/88435/dr26z114k":["arks.princeton.edu"],"http://digital.lib.cuhk.edu.hk/crbp/servlet/list":["First page of main text"]}'],
      'related_name_json_1display' => ['{"Translators":["Translator, Bob", "Translator, Carol"],"Former owner":["Translator, Carol"],"Related name":["Contributor, Donald"]}']
    }}
    subject { described_class.new solr_doc }

    it 'produces json+ld' do
      json_ld = {
        title: {'@value':'This is the Title', '@language':'eng'},
        title_sort: 'this is the title',
        abstract: 'This is a note about it.',
        description: 'This is another note.',
        extent: '340 p., ill., 24 cm',
        creator: 'Author, Alice',
        date: '1970-1972',
        created: '1970-01-01T00:00:00Z/1972-12-31T23:59:59Z',
        call_number: 'ND623.C3 M8',
        type: 'Biography',
        language: ['eng', 'spa', 'zho'],
        publisher: 'New York : Farrar, Straus Giroux, 1970.',
        :references => "{\"http://arks.princeton.edu/ark:/88435/dr26z114k\":[\"arks.princeton.edu\"],\"http://digital.lib.cuhk.edu.hk/crbp/servlet/list\":[\"First page of main text\"]}",
        contributor: ['Contributor, Donald'],
        former_owner: ['Translator, Carol'],
        identifier: "http://arks.princeton.edu/ark:/88435/dr26z114k",
        translator: ['Translator, Bob', 'Translator, Carol']
      }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end

  context 'with a human readable date and date ranges' do
    let(:solr_doc) {{
      'pub_date_display'           => ['1970'],
      'pub_date_start_sort'        => ['1970'],
      'pub_date_end_sort'          => ['1972'],
      'compiled_created_display'   => ['[between 1970 and 1972]']
    }}
    subject { described_class.new solr_doc }

    it 'produces json+ld' do
      json_ld = {
        date: '[between 1970 and 1972]',
        created: '1970-01-01T00:00:00Z/1972-12-31T23:59:59Z',
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

  context 'without dates' do
    let(:solr_doc) {{
      'title_citation_display'     => ['This is the Title'],
      'language_facet'             => ['English'],
      'language_code_s'            => ['eng'],
      'author_display'             => ['Composer, Carol'],
      'marc_relator_display'       => ['Composer']
    }}
    subject { described_class.new solr_doc }

    it 'maps the creator to dc:creator and the more specific role' do
      json_ld = {
        title: {'@value':'This is the Title', '@language': 'eng'},
        language: 'eng',
        creator: 'Composer, Carol',
        composer: 'Composer, Carol'
      }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end

  context 'without any data' do
    subject { described_class.new }

    it 'produces an empty document without errors' do
      expect { described_class.new }.to_not raise_error
      expect(described_class.new.to_h).to eq({})
    end
  end

  context 'with vernacular title' do
    let(:solr_doc) {{
      'title_citation_display'     => ['Kitāb al-Manāhil al-ṣāfīyah /', 'كتاب المناهل الصافية /'],
      'language_facet'             => ['Arabic'],
      'language_code_s'            => ['ara'],
      'author_display'             => ['Ẓufayrī, Luṭf Allāh ibn Muḥammad, 1570-1626',
                                       'ظفيري، لطف الله بن محمد'],
      'marc_relator_display'       => ['Author']
    }}
    subject { described_class.new solr_doc }

    it 'includes both the vernacular and english titles' do
      json_ld = {
        title: [{'@value':'كتاب المناهل الصافية', '@language': 'ara'},
                {'@value':'Kitāb al-Manāhil al-ṣāfīyah', '@language': 'ara-Latn'}],
        language: 'ara',
        creator: ['Ẓufayrī, Luṭf Allāh ibn Muḥammad, 1570-1626', 'ظفيري، لطف الله بن محمد'],
        author: 'Ẓufayrī, Luṭf Allāh ibn Muḥammad, 1570-1626'
      }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end

  context 'when the title language is missing' do
    let(:solr_doc) {{
      'title_citation_display'     => ['This is a test title']
    }}
    subject { described_class.new solr_doc }

    it 'produces a title statement without language tag' do
      json_ld = {title: 'This is a test title'}
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end
end
