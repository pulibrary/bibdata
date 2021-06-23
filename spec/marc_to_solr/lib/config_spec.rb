require 'rails_helper'

describe 'From traject_config.rb' do
  let(:leader) { '1234567890' }
  let(:online) { @indexer.map_record(fixture_record('9990889283506421')) }

  let(:indexer) do
    IndexerService.build
  end
  let(:fixture_dir_path) do
    Rails.root.join('spec', 'fixtures', 'marc_to_solr', 'alma')
  end
  let(:fixture_name) { 'sample1' }
  let(:fixture_file_path) do
    Rails.root.join(fixture_dir_path, "#{fixture_name}.mrx")
  end
  let(:readers) do
    indexer.reader!(fixture_file_path.to_s)
  end
  let(:reader) do
    readers.first
  end
  let(:record) do
    indexer.map_record(reader)
  end
  let(:figgy_uri) do
    "https://figgy.princeton.edu"
  end

  before do
    stub_request(:get, "#{figgy_uri}/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000")
  end

  describe "alma loading" do
    it "can map an alma record" do
      record
    end

    context 'when the record has electronic locations' do
      let(:fixture_name) { 'access_links' }

      it "can index electronic locations for alma" do
        access_links = record["electronic_access_1display"]
        expect(JSON.parse(access_links.first)).to eq("http://dx.doi.org/10.1007/BFb0088073" => ["dx.doi.org"])
      end
    end

    context 'when there are elf location codes in the record' do
      let(:fixture_name) { 'elf_codes' }

      it "does not index elf locations for alma" do
        # No ELF code.
        expect(record["location_display"]).to be_nil
        expect(record["location"]).to be_nil
        expect(record["holdings_1display"]).to be_nil
      end
    end
  end

  describe "locations" do
    let(:fixture_name) { 'locations' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    it "will index the location_code_s" do
      expect(record["location_code_s"]).to include("engineer$serials", "annex$stacks", "recap$remote", "lewis$serials")
    end
  end

  describe 'scsb locations' do
    let(:fixture_name) { 'scsb_locations' }

    it "will index a scsbnypl location" do
      expect(record["location_code_s"]).to eq ["scsbnypl"]
      expect(record["location"]).to eq ["ReCAP"]
      expect(record["advanced_location_s"]).to eq ["scsbnypl", "ReCAP"]
      expect(record["location_display"]).to eq ["ReCAP"]
    end
  end
  describe "holdings" do
    let(:fixture_name) { 'locations' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit "can index holdings" do
      holdings = JSON.parse(record["holdings_1display"][0])
      holding_1 = holdings["22188107110006421"]
      holding_2 = holdings["22188107090006421"]
      expect(holding_1["location"]).to eq "Stacks"
      expect(holding_1["library"]).to eq "Lewis Library"
      expect(holding_1["location_code"]).to eq "lewis$stacks"
      expect(holding_2["location"]).to eq "Stacks"
      expect(holding_2["library"]).to eq "Firestone Library"
      expect(holding_2["location_code"]).to eq "firestone$stacks"
    end
  end
  describe 'the cataloged_date from publishing job' do
    describe "the date cataloged facets" do
      context "When the record has 876d and 951w fields" do
        # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
        xit "will index the 876d field" do
          expect(reader['951']['w']).to be_truthy
          expect(reader['876']['d']).to be_truthy
          expect(reader['950']['b']).to be_truthy
          expect(Time.parse(record['cataloged_tdt'].first)).to eq Time.parse(reader['876']['d']).utc
        end
      end
      context "When the record has only a 950b field" do
        let(:fixture_name) { '991330600000541' }

        # This fixture needs to be located (please see https://github.com/pulibrary/bibdata/issues/1204)
        xit "will index the 950b field" do
          expect(reader['950']['b']).to be_truthy
          expect(reader['876']).to be_falsey
          expect(reader['951']).to be_falsey
          expect(Time.parse(record['cataloged_tdt'].first)).to eq Time.parse(reader['950']['b']).utc
        end
      end

      context "When the record fails to parse the time" do
        let(:fixture_name) { '991330600000541' }

        # This fixture needs to be located (please see https://github.com/pulibrary/bibdata/issues/1204)
        xit "logs the error and moves on" do
          allow(Time).to receive(:parse).and_raise(ArgumentError)
          expect { record }.not_to raise_error
        end
      end
    end

    context "When it is a SCSB partner record" do
      let(:fixture_name) { 'scsb_nypl_journal' }
      it "does not have a date cataloged facet" do
        expect(record['cataloged_tdt']).to be_nil
      end
    end
    context "When it is an eletronic record" do
      let(:fixture_name) { 'electronic_record' }

      # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
      xit "will index the 951w field" do
        expect(reader['951']['w']).to be_truthy
        expect(reader['876']).to be_falsey
        expect(reader['950']).to be_truthy
        expect(Time.parse(record['cataloged_tdt'].first)).to eq Time.parse(reader['951']['w']).utc
      end
    end
  end

  describe "electronic_portfolio_s" do
    let(:fixture_name) { 'electronic_portfolio' }

    it "returns the electronic_portfolio_s field" do
      portfolios = record['electronic_portfolio_s'].map { |p| JSON.parse(p) }
      nature = portfolios.find { |p| p['title'] == 'Nature' }
      ebsco = portfolios.find { |p| p['title'] == 'EBSCOhost Academic Search Ultimate' }
      resource1 = portfolios.find { |p| p['title'] == 'ProQuest Central' }
      resource2 = portfolios.find { |p| p['title'] == 'free eJournals' }
      resource3 = portfolios.find { |p| p['title'] == 'SciTech Premium Collection' }
      resource4 = portfolios.find { |p| p['title'] == 'PressReader' }
      resource5 = portfolios.find { |p| p['title'] == 'Biodiversity Heritage Library Free' }

      expect(nature['url']).to include('rft.mms_id=99122306151806421')
      expect(nature['desc']).to include('Available from 1869 volume: 1 issue: 1.')

      expect(nature['start']).to eq('1869')
      expect(nature['end']).to eq('latest')

      expect(ebsco['start']).to eq('1997')
      expect(ebsco['end']).to eq('2015')

      expect(resource1['start']).to eq('1990')
      expect(resource1['end']).to eq('latest')

      expect(resource2['start']).to eq('1869')
      expect(resource2['end']).to eq('1875')

      expect(resource3['start']).to eq('1990')
      expect(resource3['end']).to eq('latest')

      expect(resource4['start']).to be nil
      expect(resource4['end']).to eq('latest')

      expect(resource5['start']).to eq('1869')
      expect(resource5['end']).to eq('1923')
    end
  end
  describe "call_number_display field" do
    let(:fixture_name) { 'call_number_display' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit "returns the call_number_display field with k subfield in the beginning" do
      expect(record['call_number_display']).to eq(["Eng 20Q 6819 "])
    end
  end

  describe "call_number_browse field" do
    let(:fixture_name) { 'call_number_display' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit "returns the call_number_browse field with k subfield at the end" do
      expect(record['call_number_browse_s']).to eq(["6819 Eng 20Q"])
    end
  end

  describe "call_number_locator_display field" do
    let(:fixture_name) { 'call_number_locator' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit "returns the call_number_locator_display field with no subfield k" do
      expect(record['call_number_locator_display']).to eq([" .B7544 2003q"])
    end
  end

  describe "contained_in_s field" do
    let(:fixture_name) { 'contained_in' }

    it "indexes the 773w of the constituent record" do
      expect(record['contained_in_s']).to eq(["992953283506421"])
    end
  end

  describe 'the language_iana_s field' do
    let(:fixture_name) { 'sample1' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit 'returns a language value based on the IANA Language Subtag Registry, rejecting invalid codes' do
      expect(record['language_code_s']).to eq(['eng', '|||'])
      expect(record['language_iana_s']).to eq(['en'])
    end

    context 'when there is an added title in the 246 field' do
      let(:fixture_name) { 'added_title_246' }

      it 'returns 2 language values based on the IANA Language Subtag Registry' do
        expect(record['language_iana_s']).to eq(['ja', 'en'])
      end
    end
  end

  describe 'the isbn_display field' do
    context 'when there is an added title in the 246 field' do
      let(:fixture_name) { 'sample35' }

      it 'has more than one q subfields' do
        expect(record['isbn_display']).to eq(["9780816695706 (hardcover : alkaline paper)", "0816695709 (hardcover : alkaline paper)", "9780816695713 (paperback : alkaline paper)", "0816695717 (paperback : alkaline paper)"])
      end
    end

    context 'when there is an added title in the 246 field' do
      let(:fixture_name) { 'sample2' }

      it 'has one a subfield' do
        expect(record['isbn_display']).to eq(["0947752196"])
      end
    end
  end

  describe 'the id field' do
    let(:fixture_name) { 'sample1' }

    it 'has exactly 1 value' do
      expect(record['id'].length).to eq 1
    end
  end
  describe 'numeric_id_b' do
    let(:fixture_name) { 'sample1' }
    it 'returns desired bool' do
      expect(record['numeric_id_b'].first).to eq true
    end

    context 'with a record with a non-numerica bib. ID' do
      let(:fixture_name) { 'scsb_nypl_journal' }
      it 'returns desired bool' do
        expect(record['numeric_id_b'].first).to eq false
      end
    end
  end
  describe 'the title_sort field' do
    let(:fixture_name) { 'sample1' }

    it 'does not have initial articles' do
      expect(record['title_sort'][0].start_with?('Advanced concepts')).to be_truthy
    end
  end
  describe 'the author_display field' do
    let(:fixture_name) { 'sample1' }

    it 'takes from the 100 field' do
      expect(record['author_display'][0]).to eq 'Singh, Digvijai, 1934-'
    end

    context 'when there is only a 100 field' do
      let(:fixture_name) { 'sample2' }

      it 'shows only 100 field' do
        expect(record['author_display'][0]).to eq 'White, Michael M.'
      end
    end

    context 'when there is a 110 field' do
      let(:fixture_name) { 'sample3' }

      it 'shows 110 field' do
        expect(record['author_display'][0]).to eq 'World Data Center A for Glaciology'
      end
    end
  end

  describe 'the author_citation_display field' do
    let(:fixture_name) { 'sample1' }

    it 'shows only the 100 a subfield' do
      expect(record['author_citation_display'][0]).to eq 'Singh, Digvijai'
    end

    context 'when there is a 700 subfield' do
      let(:fixture_name) { 'sample36' }

      it 'shows only the 700 a subfield' do
        expect(record['author_citation_display']).to include 'Ishizuka, Harumichi'
      end
    end
  end
  describe 'the title vernacular display' do
    let(:fixture_name) { 'scsb_cul_alt_title' }

    it 'is a single value for scsb records' do
      expect(record['title_vern_display'].length).to eq(1)
    end

    context '' do
      let(:fixture_name) { 'title_vern_display' }

      it 'is a single value for pul records' do
        expect(record['title_vern_display'].length).to eq(1)
      end
    end
  end
  describe 'publication_place_facet field' do
    let(:fixture_name) { 'sample1' }

    it 'maps the 3-digit code in the 008[15-17] to a name' do
      expect(record['publication_place_facet']).to eq ['Michigan']
    end

    context 'when the publication place is a 2-digit code' do
      let(:fixture_name) { 'added_title_246' }

      it 'maps the 2-digit code in the 008[15-17] to a name' do
        expect(record['publication_place_facet']).to eq ['Japan']
      end
    end
  end
  describe 'the pub_citation_display field' do
    let(:fixture_name) { 'sample2' }

    it 'shows the the 260 a and b subfields' do
      expect(record['pub_citation_display']).to include 'London: Firethorn Press'
    end
  end
  describe 'notes from record show up in the notes_index' do
    let(:fixture_name) { 'sample34' }

    it 'shows tag 500 and 538' do
      expect(record['notes_index']).to include('DVD ; all regions ; Dolby digital.', 'Originally released as documentary films 1956-1971.')
    end
  end
  describe 'publication end date' do
    let(:place) { 'Cincinnati, Ohio :' }
    let(:name) { 'American Drama Institute,' }
    let(:date) { 'c1991-' }
    let(:date_full) { 'c1991-1998' }
    let(:ceased_008) do
      {
        '008' => '911219d19912007ohufr-p-------0---a0eng-c'
      }
    end
    let(:not_ceased_008) do
      {
        '008' => '911219c19912007ohufr-p-------0---a0eng-c'
      }
    end
    let(:no_date_008) do
      {
        '008' => '911219d1991    ohufr-p-------0---a0eng-c'
      }
    end
    let(:date_9999_008) do
      {
        '008' => '911219d19919999ohufr-p-------0---a0eng-c'
      }
    end
    let(:date_199u_008) do
      {
        '008' => '911219d1991199uohufr-p-------0---a0eng-c'
      }
    end
    let(:p260) do
      {
        "260" => {
          "ind1" => " ",
          "ind2" => " ",
          "subfields" => [{ "a" => place }, { "b" => name }, { "c" => date }]
        }
      }
    end
    let(:p260_complete) do
      {
        "260" => {
          "ind1" => " ",
          "ind2" => " ",
          "subfields" => [{ "a" => place }, { "b" => name }, { "c" => date_full }]
        }
      }
    end
    let(:no_date_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [no_date_008, p260], 'leader' => leader)) }
    let(:date_9999_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [date_9999_008, p260], 'leader' => leader)) }
    let(:date_199u_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [date_199u_008, p260], 'leader' => leader)) }
    let(:not_ceased_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [not_ceased_008, p260], 'leader' => leader)) }
    let(:ceased_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [ceased_008, p260], 'leader' => leader)) }
    let(:no_trailing_date_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [ceased_008, p260_complete], 'leader' => leader)) }

    context 'when the record has an indicator2 tag' do
      let(:fixture_name) { 'sample34' }

      it 'displays 264 tag sorted by indicator2' do
        expect(record['pub_created_display']).to eq ["[Paris] : Les Films de La Pleiade, 1956-1971.", "[Brooklyn, N.Y.] : Icarus Films, [2017]", "©1956-1971"]
      end
    end
    it 'displays when 008-6 is d and an end date is present in the 008' do
      expect(ceased_marc['pub_created_display']).to include 'Cincinnati, Ohio : American Drama Institute, c1991-2007'
    end
    it 'when u is present in the end date string convert it to a 9' do
      expect(date_199u_marc['pub_created_display']).to include 'Cincinnati, Ohio : American Drama Institute, c1991-1999'
    end
    it 'does not display when 008-6 is d but end date is 9999' do
      expect(date_9999_marc['pub_created_display']).to include 'Cincinnati, Ohio : American Drama Institute, c1991-'
    end
    it 'does not display when 008-6 is d but end date is not present' do
      expect(no_date_marc['pub_created_display']).to include 'Cincinnati, Ohio : American Drama Institute, c1991-'
    end
    it 'does not display when 008-6 is not d' do
      expect(not_ceased_marc['pub_created_display']).to include 'Cincinnati, Ohio : American Drama Institute, c1991-'
    end
    it 'does not display when the publisher field ends with a character other than a dash' do
      expect(no_trailing_date_marc['pub_created_display']).to include 'Cincinnati, Ohio : American Drama Institute, c1991-1998'
    end
  end
  describe 'cjk-only fields' do
    let(:fixture_name) { 'cjk_only' }

    it 'displays 880 in pub_created_vern_display and subject field' do
      expect(record['pub_created_vern_display']).to eq ['[China : s.n.], 清乾隆癸亥 [8年, 1743]']
      expect(record['cjk_subject']).to eq ['子部 醫家類 兒科.']
    end
    it 'cjk_all contains 880 fields in a single string' do
      expect(record['cjk_all'][0]).to include('葉其蓁. 抱乙子幼科指掌遺藁 : 五卷 / 葉其蓁編輯 ; [葉] 大本述. 幼科指掌. [China : s.n.], 清乾隆癸亥 [8年, 1743] 子部 醫家類 兒科.')
    end
    it 'cjk_notes contains 880 fields associated with 5xx fields' do
      expect(record['cjk_notes'][0]).to include('乾隆癸亥李大倫"序"言刻書事.')
      expect(record['cjk_notes'][0]).not_to include('子部')
    end
  end
  describe 'related_name_json_1display' do
    let(:fixture_name) { 'related_names' }
    it 'trims punctuation the same way as author_s facet' do
      rel_names = JSON.parse(record['related_name_json_1display'][0])
      rel_names['Related name'].each { |n| expect(record['author_s']).to include(n) }
    end

    context 'when the 246 field has multiple roles' do
      let(:fixture_name) { 'label_i_246' }
      it 'allows multiple roles from single field' do
        rel_names = JSON.parse(record['related_name_json_1display'][0])
        expect(rel_names['Film director']).to include('Kim, Tŏk-su')
        expect(rel_names['Screenwriter']).to include('Kim, Tŏk-su')
      end
    end
  end

  describe 'access_facet' do
    let(:fixture_name) { 'sample3' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit 'value is in the library for non-electronic records' do
      expect(record['access_facet']).to include 'In the Library'
      expect(record['access_facet']).not_to include 'Online'
    end

    context 'when the record is an online resource' do
      let(:fixture_name) { 'online' }

      it 'value is online for records where 856 field second indicator is 0' do
        expect(record['access_facet']).to include 'Online'
        expect(record['access_facet']).not_to include 'In the Library'
      end
    end

    context 'when the record is both a physical and online resource' do
      let(:fixture_name) { 'online_at_library' }

      # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
      xit 'value can be both in the library and online when there are multiple holdings' do
        expect(record['access_facet']).to include 'Online'
        expect(record['access_facet']).to include 'In the Library'
      end
    end

    context 'when the record is a HathiTrust resource' do
      before do
        ENV['RUN_HATHI_COMPARE'] = 'true'
      end

      after do
        ENV['RUN_HATHI_COMPARE'] = ''
      end
      let(:fixture_name) { 'hathi_permanent' }

      # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
      xit 'value include online when record is present in hathi report with permanent access' do
        expect(record['access_facet']).to contain_exactly('Online', 'In the Library')
        expect(record['hathi_identifier_s']).to contain_exactly("mdp.39015036879529")
      end
    end
  end
  # TODO: Replace with Alma
  describe 'holdings_1display' do
    # TODO: Replace with Alma
    # Revisit while working on https://github.com/pulibrary/bibdata/issues/921
    let(:holding_fixture_file_path) do
      Rails.root.join(fixture_dir_path, "7617477.mrx")
    end
    let(:holding_readers) do
      indexer.reader!(holding_fixture_file_path.to_s)
    end
    let(:holding_reader) do
      holding_readers.first
    end
    let(:holding_document) do
      indexer.map_record(holding_reader)
    end
    let(:holding_field) do
      holding_document['holdings_1display'].first
    end
    let(:holding_block) do
      JSON.parse(holding_field)
    end
    let(:holding_records_fixture_path) do
      Rails.root.join("fixtures", "marc_to_solr", "7617477-holdings.json")
    end
    let(:holding_records_fixture_file) do
      File.read(holding_records_fixture_path)
    end
    let(:holding_records_fixture_json) do
      JSON.parse(holding_records_fixture_file)
    end
    let(:holding_records) do
      holding_records_fixture_json.map { |holding| MARC::Record.new_from_hash(holding) }
    end

    xit 'groups holding info into a hash keyed on the mfhd id' do
      holding_records.each do |holding|
        holding_id = holding['001'].value
        expect(holding_block[holding_id]['location_code']).to include(holding['852']['b'])
        expect(holding_block[holding_id]['location_note']).to include(holding['852']['z'])
      end
    end
    # TODO: Replace with Alma
    # Revisit while working on https://github.com/pulibrary/marc_liberation/issues/921
    xit 'includes holding 856s keyed on mfhd id' do
      holding_records.each do |holding|
        holding_id = holding['001'].value
        electronic_access = holding_block[holding_id]['electronic_access']
        expect(electronic_access[holding['856']['u']]).to include(holding['856']['z'])
      end
    end
    # TODO: Replace with Alma
    # Revisit while working on https://github.com/pulibrary/marc_liberation/issues/921
    xit 'holding 856s are excluded from electronic_access_1display' do
      electronic_access = JSON.parse(holding_document['electronic_access_1display'].first)
      expect(electronic_access).not_to include('holding_record_856s')
    end
  end
  describe 'excluding locations from library facet' do
    let(:fixture_name) { 'online' }

    # TODO: Replace with Alma
    # Question: Is this still valid?
    # Revisit while working on https://github.com/pulibrary/bibdata/issues/921
    xit 'when location is online' do
      expect(record['location_code_s']).to include 'online$elf1'
      expect(record['location_display']).to include 'Electronic Access - elf1 Internet Resources'
      expect(record['location']).to eq ['Electronic Access']
    end
    context 'when location codes that do not map to labels' do
      let(:fixture_name) { 'invalid_location_code' }

      # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
      xit 'generates the "invalidcode" value without a display label' do
        expect(record['location_code_s']).to include 'invalidcode'
        expect(record['location_display']).to be_nil
        expect(record['location']).to be_nil
      end
    end
  end
  describe 'location facet values for Recap items' do
    let(:fixture_name) { 'added_title_246' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit 'marquand recap items have a location value of marquand and recap' do
      expect(record['location_display']).to eq ['Remote Storage: Marquand Library use only']
      expect(record['location']).to eq ['ReCAP']
    end
    context 'when the record is for a non-rare recap item' do
      let(:fixture_name) { 'online_at_library' }

      # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
      xit 'non-rare recap items only have a location value of recap' do
        expect(record['location_display']).to include 'Mudd Off-Site Storage: Contact mudd@princeton.edu'
        expect(record['location']).to include 'ReCAP'
        expect(record['location']).not_to include 'Mudd Manuscript Library'
      end
    end
  end

  let(:record_fixture_path) { fixture_record(id) }
  let(:current_record) { @indexer.map_record(record_fixture_path) }

  describe 'including libraries and codes in advanced_location_s facet' do
    let(:fixture_name) { 'locations' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit 'lewis library included with lewis code' do
      expect(record['advanced_location_s']).to include 'lewis$stacks'
      expect(record['advanced_location_s']).to include 'Lewis Library'
    end
    # TODO: Replace with Alma.
    # Question: Is this still valid?
    context 'when the record is for an online record with an elf2 location code' do
      let(:fixture_name) { 'elf2' }
      xit 'online is included' do
        expect(record['advanced_location_s']).to include 'elf2'
        expect(record['advanced_location_s']).to include 'Online'
      end
    end

    context 'when the location code encodes the Lewis Library' do
      let(:fixture_name) { 'locations' }

      # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
      xit 'library is excluded from location_code_s' do
        expect(record['location_code_s']).to include 'lewis$stacks'
        expect(record['location_code_s']).not_to include 'Lewis Library'
      end
    end
  end
  describe 'other_title_display array 246s included' do
    let(:fixture_name) { 'added_title_246' }

    it 'regardless of 2nd indicator value' do
      expect(record['other_title_display']).to include 'Bi ni itaru yamai'
      expect(record['other_title_display']).to include 'Morimura Yasumasa, the sickness unto beauty'
      expect(record['other_title_display']).to include 'Sickness unto beauty'
    end

    context 'regardless of 2nd indicator value' do
      let(:fixture_name) { 'other_title_246' }

      it 'when no 2nd indicator' do
        expect(record['other_title_display']).to include 'Episcopus, civitas, territorium'
      end
    end

    context 'regardless of 2nd indicator value' do
      let(:fixture_name) { 'label_i_246' }

      it 'excludes other title when subfield $i is present' do
        expect(record['other_title_display']).to be_nil
      end
    end
  end
  describe 'other_title_1display 246s hash' do
    let(:fixture_name) { 'added_title_246' }

    it 'excludes titles with 2nd indicator labels' do
      expect(record['other_title_1display']).to be_nil
    end

    context 'when there is a 246$i label' do
      let(:fixture_name) { 'label_i_246' }

      it 'uses label from $i when available' do
        other_title_hash = JSON.parse(record['other_title_1display'].first)
        expect(other_title_hash['English title also known as']).to include 'Dad for rent'
      end
    end
  end
  describe 'multiple 245s' do
    let(:fixture_name) { 'sample3' }

    it 'only uses first 245 in single-valued title_display field' do
      expect(record['title_display'].length).to eq 1
    end
  end
  describe 'multiformat record' do
    let(:fixture_name) { 'manuscript_book' }

    it 'manuscript book includes both formats, manuscript first' do
      expect(record['format']).to eq ['Manuscript', 'Book']
    end
  end
  describe '852 $b $c location code processing' do
    let(:fixture_name) { 'locations' }

    # This test needs to be restored (please see https://github.com/pulibrary/bibdata/issues/1204)
    xit 'supports multiple location codes in separate 852s' do
      expect(record['location_code_s']).to eq(["lewis$stacks", "firestone$stacks"])
    end
    # TODO: ALMA
    # it 'only includes the first $b within a single tag' do
    # end
  end

  describe 'mixing extract_marc and everything_after_t' do
    let(:t400) { { "400" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "t" => "TITLE" }] } } }
    let(:t440) { { "440" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "t" => "AWESOME" }, { "a" => "John" }, { "n" => "1492" }, { "k" => "dont ignore" }] } } }

    it 'includes 400 field when 440 missing for series_title_index field' do
      no_440 = indexer.map_record(MARC::Record.new_from_hash('fields' => [t400], 'leader' => leader))
      expect(no_440['series_title_index']).to include('TITLE')
    end
    it 'includes 400 and 440 field for series_title_index field' do
      yes_440 = indexer.map_record(MARC::Record.new_from_hash('fields' => [t400, t440], 'leader' => leader))
      expect(yes_440['series_title_index']).to match_array(['TITLE', 'John 1492'])
    end

    context 'when there are no matching values' do
      let(:fixture_name) { 'sample1' }

      it 'excludes series_title_index field when no matching values' do
        expect(record['series_title_index']).to be_nil
      end
    end
  end

  describe 'both a and t must be present in linked title field' do
    let(:t760) { { "760" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "t" => "TITLE" }] } } }
    let(:a762) { { "762" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "NAME" }] } } }
    let(:at765) { { "765" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "Both" }, { "t" => "name and title" }] } } }
    let(:linked_record) { indexer.map_record(MARC::Record.new_from_hash('fields' => [t760, a762, at765], 'leader' => leader)) }

    it 'only includes 765at' do
      expect(linked_record['linked_title_s']).to match_array(['Both name and title'])
    end

    it 'linked title field included in name-title browse' do
      expect(linked_record['name_title_browse_s']).to include('Both name and title')
    end
  end

  describe '#related_record_info_display' do
    let(:i776) { { "776" => { "ind1" => "", "ind2" => "", "subfields" => [{ "i" => "Test description" }] } } }
    let(:linked_record) { indexer.map_record(MARC::Record.new_from_hash('fields' => [i776], 'leader' => leader)) }

    it 'indexes the 776$i value' do
      expect(linked_record['related_record_info_display']).to include('Test description')
    end
  end

  describe 'name_uniform_title_display field' do
    let(:n100) { { "100" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "880-01" }, { "a" => "Name," }] } } }
    let(:n100_vern) { { "880" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "100-01" }, { "a" => "AltName ;" }] } } }
    let(:t240) { { "240" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "880-02" }, { "a" => "Uniform Title," }, { "p" => "5" }] } } }
    let(:t240_vern) { { "880" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "240-02" }, { "a" => "AltUniform Title," }, { "p" => "5" }] } } }
    let(:t245) { { "245" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "880-03" }, { "a" => "Title 245a" }] } } }
    let(:t245_vern) { { "880" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "245-03" }, { "a" => "VernTitle 245a" }] } } }
    let(:uniform_title) { indexer.map_record(MARC::Record.new_from_hash('fields' => [n100, n100_vern, t240, t240_vern, t245, t245_vern], 'leader' => leader)) }
    let(:no_uniform_title) { indexer.map_record(MARC::Record.new_from_hash('fields' => [n100, n100_vern, t245, t245_vern], 'leader' => leader)) }

    it 'name title browse field includes both scripts, excludes 245 with uniform title present' do
      expect(JSON.parse(uniform_title['name_uniform_title_1display'][0])).to match_array([['Name.', 'Uniform Title,', '5'],
                                                                                          ['AltName.', 'AltUniform Title,', '5']])
      expect(uniform_title['name_title_browse_s']).to match_array(['Name. Uniform Title', 'Name. Uniform Title, 5',
                                                                   'AltName. AltUniform Title', 'AltName. AltUniform Title, 5'])
    end

    it 'name title browse field includes both scripts, includes 245 when no uniform title present' do
      expect(no_uniform_title['name_title_browse_s']).to match_array(["Name. Title 245a",
                                                                      "AltName. VernTitle 245a"])
    end
  end

  describe 'series 490 dedup, non-filing' do
    let(:s490) { { "490" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "Series title" }] } } }
    let(:s830) { { "830" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "Series title." }] } } }
    let(:s440) { { "440" => { "ind1" => "", "ind2" => "4", "subfields" => [{ "a" => "The Series" }] } } }
    let(:record) { indexer.map_record(MARC::Record.new_from_hash('fields' => [s490, s830, s440], 'leader' => leader)) }

    it '490s are not included when they are covered by another series field' do
      expect(record['series_display']).to match_array(['Series title.', 'The Series'])
    end

    it 'matches for other works within series ignore non-filing characters, trim punctuation' do
      expect(record['more_in_this_series_t']).to match_array(['Series title', 'Series'])
    end
  end
  describe 'senior thesis 502 note' do
    let(:senior_thesis_502) { { "502" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => "Thesis (Senior)-Princeton University" }] } } }
    let(:senior_thesis_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [senior_thesis_502], 'leader' => leader)) }
    let(:whitespace_502) { { "502" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => "Thesis (Senior)  -- Princeton University" }] } } }
    let(:senior_thesis_whitespace) { indexer.map_record(MARC::Record.new_from_hash('fields' => [whitespace_502], 'leader' => leader)) }
    let(:subfield_bc_502) { { "502" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "b" => "Senior" }, { "c" => "Princeton University" }] } } }
    let(:thesis_bc_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [subfield_bc_502], 'leader' => leader)) }

    it 'Princeton senior theses are properly classified' do
      expect(senior_thesis_marc['format']).to include 'Senior thesis'
    end
    it 'whitespace is ignored in classifying senior thesis' do
      expect(senior_thesis_whitespace['format']).to include 'Senior thesis'
    end
    it 'senior thesis note can be split across subfields $b and $c' do
      expect(thesis_bc_marc['format']).to include 'Senior thesis'
    end
  end

  describe 'subject display and unstem fields' do
    let(:s650_lcsh) { { "650" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "LC Subject" }] } } }
    let(:s650_sk) { { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Siku Subject" }, { "2" => "sk" }] } } }
    let(:s650_exclude) { { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Exclude from subject browse" }, { "2" => "bad" }] } } }
    let(:subject_marc) { indexer.map_record(MARC::Record.new_from_hash('fields' => [s650_lcsh, s650_sk, s650_exclude], 'leader' => leader)) }

    it 'include the sk and lc subjects in separate fields, exlcude other subject types' do
      expect(subject_marc['lc_subject_display']).to match_array(['LC Subject'])
      expect(subject_marc['subject_unstem_search']).to match_array(['LC Subject'])
      expect(subject_marc['siku_subject_display']).to match_array(['Siku Subject'])
      expect(subject_marc['siku_subject_unstem_search']).to match_array(['Siku Subject'])
    end
  end
  describe 'form_genre_display' do
    subject(:form_genre_display) { indexer.map_record(marc_record) }
    let(:leader) { '1234567890' }
    let(:field_655) do
      {
        "655" => {
          "ind1" => "",
          "ind2" => "7",
          "subfields" => [
            {
              "a" => "Culture."
            },
            {
              "v" => "Awesome"
            },
            {
              "x" => "Dramatic rendition"
            },
            {
              "y" => "19th century."
            },
            {
              "2" => "lcgft"
            }
          ]
        }
      }
    end
    let(:field_655_2) do
      {
        "655" => {
          "ind1" => "",
          "ind2" => "7",
          "subfields" => [
            {
              "a" => "Poetry"
            },
            {
              "x" => "Translations into French"
            },
            {
              "v" => "Maps"
            },
            {
              "y" => "19th century."
            },
            {
              "2" => "aat"
            }
          ]
        }
      }
    end
    let(:marc_record) do
      MARC::Record.new_from_hash('leader' => leader, 'fields' => [field_655, field_655_2])
    end
    it "indexes the subfields as semicolon-delimited values" do
      expect(form_genre_display["lcgft_s"].first).to eq("Culture#{SEPARATOR}Awesome#{SEPARATOR}Dramatic rendition#{SEPARATOR}19th century")
      expect(form_genre_display["aat_s"].last).to eq("Poetry#{SEPARATOR}Translations into French#{SEPARATOR}Maps#{SEPARATOR}19th century")
    end
  end
end
