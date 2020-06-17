require 'rails_helper'

RSpec.describe JSONLDRecord, type: :model do
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
      'location_code_s'            => ['f', 'anxafst'],
      'genre_facet'                => ['Biography'],
      'language_code_s'            => ['eng', 'spa', 'chi'],
      'author_display'             => ['Author, Alice'],
      'related_name_json_1display' => ['{"Translators":["Translator, Bob", "Translator, Carol"],"Former owner":["Translator, Carol"],"Related name":["Contributor, Donald"]}'],
      'uniform_title_s'            => ['Declaration of Independence'],
      'language_display'           => ['Text in German.'],
      'binding_note_display'       => ['In half-morocco slipcase.'],
      'provenance_display'         => ['Provenance: Johann Anton André, of Offenbach, 1799; Philharmonische Gesellschaft, Laibach (Ljubljana); Robert Ammann.'],
      'source_acquisition_display'         => ['Obtained, Nov. 16, 1961, at Stargardt Sale of the collection of Dr. Robert Ammann.'],
      'references_display'         => ["Stillwell B460.", "Goff B-526."],
      # Provide two ARKs so we can make the first one point to a finding aid to
      # ensure it isn't picked.
      'electronic_access_1display' => ["{\"http://arks.princeton.edu/ark:/88435/47429918s\":[\"arks.princeton.edu\",\"Finding aid\"],\"http://arks.princeton.edu/ark:/88435/7p88ch283\":[\"arks.princeton.edu\"]}"],
      'indexed_in_display'         => ['Example']
    }}
    subject { described_class.new solr_doc }

    it 'produces json+ld' do
      # Stub the first ARK to point to findingaids site so it isn't picked as
      # the identifier. We want to return the first non-finding-aid ARK for
      # Figgy to import.
      stub_ezid(shoulder: "88435", blade: "47429918s", location: "http://findingaids.princeton.edu/bla")
      stub_ezid(shoulder: "88435", blade: "7p88ch283")
      json_ld = {
        title: { '@value':'This is the Title', '@language':'eng' },
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
        contributor: ['Contributor, Donald'],
        former_owner: ['Translator, Carol'],
        identifier: "http://arks.princeton.edu/ark:/88435/7p88ch283",
        translator: ['Translator, Bob', 'Translator, Carol'],
        uniform_title: 'Declaration of Independence',
        text_language: 'Text in German.',
        binding_note: 'In half-morocco slipcase.',
        provenance: 'Provenance: Johann Anton André, of Offenbach, 1799; Philharmonische Gesellschaft, Laibach (Ljubljana); Robert Ammann.',
        source_acquisition: 'Obtained, Nov. 16, 1961, at Stargardt Sale of the collection of Dr. Robert Ammann.',
        references: ['Stillwell B460.', 'Goff B-526.'],
        indexed_by: 'Example',
        location: ['F ND623.C3 M8', 'ANXAFST ND623.C3 M8'],
        electronic_locations: [{ "@id" => "http://arks.princeton.edu/ark:/88435/47429918s", "label" => "arks.princeton.edu" }]
      }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end

  context "with a program linked" do
    let(:solr_doc) {{
      'electronic_access_1display' => ["{\"http://lib-dbserver.princeton.edu/music/programs/2015-04-24-25.pdf\":[\"Program.\"]}"]
    }}
    subject { described_class.new solr_doc }
    it "displays it" do
      expect(subject.to_h["electronic_locations"]).to eq [
        {
          "@id" => "http://lib-dbserver.princeton.edu/music/programs/2015-04-24-25.pdf",
          "label" => "Program."
        }
      ]
    end
  end

  context "with IIIF manifest path identifiers" do
    let(:solr_doc) {{
      # Provide two arks - one in the iiif manifest paths (a known figgy ark),
      # and one without, to make sure it picks the Figgy one.
      'electronic_access_1display' => ["{\"https://catalog.princeton.edu/catalog/7849027#view\":[\"Digital content\"],\"http://arks.princeton.edu/ark:/88435/cj82k733w\":[\"arks.princeton.edu\",\"Yemeni Manuscript Digitization Initiative\"],\"iiif_manifest_paths\":{\"http://arks.princeton.edu/ark:/88435/qv33rx40r\":\"https://figgy.princeton.edu/concern/scanned_resources/28cfa04a-b699-427c-84e6-998b74f9669e/manifest\"}}"],
      'indexed_in_display'         => ['Example']
    }}
    subject { described_class.new solr_doc }
    it "chooses the ark with a manifest first" do
      stub_ezid(shoulder: "88435", blade: "qv33rx40r")
      stub_ezid(shoulder: "88435", blade: "cj82k733w")
      expect(subject.to_h["identifier"]).to eq "http://arks.princeton.edu/ark:/88435/qv33rx40r"
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
        title: { '@value':'This is the Title', '@language': 'eng' },
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
        title: { '@value':'This is the Title', '@language': 'eng' },
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
      "title_no_h_index" =>  [
        "Kitāb al-Manāhil al-ṣāfīyah / Luṭf Allāh ibn Muḥammad Ẓufayrī.",
        "كتاب المناهل الصافية / لطف الله بن محمد] [ظفيري"
      ],
      'language_facet'             => ['Arabic'],
      'language_code_s'            => ['ara'],
      'author_display'             => ['Ẓufayrī, Luṭf Allāh ibn Muḥammad, 1570-1626',
                                       'ظفيري، لطف الله بن محمد'],
      'marc_relator_display'       => ['Author']
    }}
    subject { described_class.new solr_doc }

    it 'includes both the vernacular and english titles' do
      json_ld = {
        title: [{ '@value':'كتاب المناهل الصافية / لطف الله بن محمد] [ظفيري', '@language': 'ara' },
                { '@value':'Kitāb al-Manāhil al-ṣāfīyah / Luṭf Allāh ibn Muḥammad Ẓufayrī.', '@language': 'ara-Latn' }],
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
      json_ld = { title: 'This is a test title' }
      expect(subject.to_h.symbolize_keys).to eq(json_ld)
    end
  end

  context 'with a digital cicognara number' do
    let(:solr_doc) {{
      'standard_no_1display' => ["{\"Cico\":[\"1200-1\"],\"Dclib\":[\"cico:bk5\"]}"]
    }}
    subject { described_class.new solr_doc }

    it 'includes the digital cicognara number in the local_identifier field' do
      expect(subject.to_h['local_identifier']).to include 'cico:bk5'
    end
  end

  context 'with multiple titles and no language codes' do
    let(:solr_doc) {{
      'title_citation_display' => ['First title /', '中国少数民族文字珍稀典籍汇编 /'],
      'language_code_s'        => ['mul']
    }}
    subject { described_class.new solr_doc }

    it "returns the vernacular title" do
      expect(subject.vernacular_title).to eq("中国少数民族文字珍稀典籍汇编")
    end

    it "returns the romanized title" do
      expect(subject.roman_title).to eq("First title")
    end
  end
end
