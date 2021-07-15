require 'rails_helper'

describe 'From traject_config.rb' do
  let(:leader) { '1234567890' }
  let(:online) { @indexer.map_record(fixture_record('9990889283506421')) }

  def fixture_record(fixture_name)
    f = File.expand_path("../../../fixtures/marc_to_solr/#{fixture_name}.mrx", __FILE__)
    @indexer.reader!(f).first
  end

  before(:all) do
    stub_request(:get, "https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000")

    @indexer = IndexerService.build
    @sample1 = @indexer.map_record(fixture_record('99276293506421'))
    @sample2 = @indexer.map_record(fixture_record('993456823506421'))
    @sample3 = @indexer.map_record(fixture_record('993213506421'))
    @sample34 = @indexer.map_record(fixture_record('99105855523506421'))
    @sample35 = @indexer.map_record(fixture_record('9990567203506421'))
    @sample36 = @indexer.map_record(fixture_record('9981818493506421'))
    @sample37 = @indexer.map_record(fixture_record('9976174773506421'))
    @sample38 = @indexer.map_record(fixture_record('99121576653506421'))
    @sample39 = @indexer.map_record(fixture_record('99110599413506421'))
    @sample40 = @indexer.map_record(fixture_record('9941598513506421'))
    @record_call_number1 = @indexer.map_record(fixture_record('9957270023506421'))
    @record_call_number2 = @indexer.map_record(fixture_record('99103141233506421'))
    @record_call_number_nil = @indexer.map_record(fixture_record('99102664603506421'))
    @manuscript_book = @indexer.map_record(fixture_record('9959060243506421'))
    @added_title_246 = @indexer.map_record(fixture_record('9930602883506421'))
    @related_names = @indexer.map_record(fixture_record('9919643053506421'))
    @label_i_246 = @indexer.map_record(fixture_record('9990315453506421'))
    @online_at_library = @indexer.map_record(fixture_record('9979160443506421'))
    @other_title_246 = @indexer.map_record(fixture_record('9979105993506421'))
    @title_vern_display = @indexer.map_record(fixture_record('9948545023506421'))
    @scsb_nypl = @indexer.map_record(fixture_record('SCSB-8157262'))
    @scsb_alt_title = @indexer.map_record(fixture_record('scsb_cul_alt_title'))
    @recap_record = @indexer.map_record(fixture_record('994081873506421'))
    ENV['RUN_HATHI_COMPARE'] = 'true'
    @hathi_permanent = @indexer.map_record(fixture_record('9914591663506421'))
    ENV['RUN_HATHI_COMPARE'] = ''
  end

  describe "alma loading" do
    it "can map an alma record" do
      record = @indexer.map_record(fixture_record('9918573506421'))
    end
    it "can index electronic locations for alma" do
      record = @indexer.map_record(fixture_record('9918573506421'))
      access_links = record["electronic_access_1display"]
      expect(JSON.parse(access_links.first)).to eq("http://dx.doi.org/10.1007/BFb0088073" => ["dx.doi.org"])
    end
    it "does not index elf locations for alma" do
      expect(@sample38["location_display"]).to be_nil
      expect(@sample38["location"]).to be_nil
      expect(@sample38["holdings_1display"]).to be_nil
    end
  end
  describe "locations" do
    it "will index the location_code_s" do
      record = @indexer.map_record(fixture_record('9992320213506421'))
      expect(record["location_code_s"]).to eq ["lewis$stacks", "firestone$stacks"]
    end
  end

  describe 'scsb locations' do
    it "will index a scsbnypl location" do
      expect(@scsb_nypl["location_code_s"]).to eq ["scsbnypl"]
      expect(@scsb_nypl["location"]).to eq ["ReCAP"]
      expect(@scsb_nypl["advanced_location_s"]).to eq ["scsbnypl", "ReCAP"]
      expect(@scsb_nypl["location_display"]).to eq ["ReCAP"]
    end
  end
  describe "holdings" do
    it "can index holdings" do
      record = @indexer.map_record(fixture_record('9992320213506421'))
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
        it "will index the 876d field" do
          record = fixture_record('99211662100521')
          indexed_record = @indexer.map_record(record)
          expect(record['951']['w']).to be_truthy
          expect(record['876']['d']).to be_truthy
          expect(record['950']['b']).to be_truthy
          expect(Time.parse(indexed_record['cataloged_tdt'].first)).to eq Time.parse(record['876']['d']).utc
        end
      end
      context "When the record has only a 950b field" do
        it "will index the 950b field" do
          record = fixture_record('991330600000541')
          indexed_record = @indexer.map_record(record)
          expect(record['950']['b']).to be_truthy
          expect(record['876']).to be_falsey
          expect(record['951']).to be_falsey
          expect(Time.parse(indexed_record['cataloged_tdt'].first)).to eq Time.parse(record['950']['b']).utc
        end
      end

      context "When the record fails to parse the time" do
        it "logs the error and moves on" do
          allow(Time).to receive(:parse).and_raise(ArgumentError)
          expect { @indexer.map_record(fixture_record('9992320213506421')) }.not_to raise_error
        end
      end
    end

    context "When it is a SCSB partner record" do
      it "does not have a date cataloged facet" do
        expect(@scsb_nypl['cataloged_tdt']).to be_nil
      end
    end
    context "When it is an eletronic record" do
      it "will index the 951w field" do
        record = fixture_record('99122424622606421')
        indexed_record = @indexer.map_record(record)
        expect(record['951']['w']).to be_truthy
        expect(record['876']).to be_falsey
        expect(record['950']).to be_truthy
        expect(Time.parse(indexed_record['cataloged_tdt'].first)).to eq Time.parse(record['951']['w']).utc
      end
    end
  end

  describe "electronic_portfolio_s" do
    it "returns the electronic_portfolio_s field" do
      record = @indexer.map_record(fixture_record('99122306151806421'))
      portfolios = record['electronic_portfolio_s'].map { |p| JSON.parse(p) }
      nature = portfolios.find { |p| p['title'] == 'Nature' }
      ebsco = portfolios.find { |p| p['title'] == 'EBSCOhost Academic Search Ultimate' }
      resource1 = portfolios.find { |p| p['title'] == 'Resource1' }
      resource2 = portfolios.find { |p| p['title'] == 'Resource2' }
      resource3 = portfolios.find { |p| p['title'] == 'Resource3' }
      resource4 = portfolios.find { |p| p['title'] == 'Resource4' }

      expect(nature['url']).to include '&portfolio_pid=53443322610006421'
      expect(nature['desc']).to eq 'Available from 1869 volume: 1 issue: 1.'

      # Date range with explicit start and no end date
      expect(nature['start']).to eq '1869'
      expect(nature['end']).to eq 'latest'

      # Date range with explicit start and end
      expect(ebsco['start']).to eq '1997'
      expect(ebsco['end']).to eq '2015'

      # Date range with less than or equal to embargo
      expect(resource1['start']).to eq '2019'
      expect(resource1['end']).to eq 'latest'

      # Date range with less than embargo
      expect(resource2['start']).to eq '2020'
      expect(resource2['end']).to eq 'latest'

      # Date range with greater than embargo
      expect(resource3['start']).to eq '1990'
      expect(resource3['end']).to eq '2018'

      # Date range with greater than or equal to embargo
      expect(resource4['start']).to eq '1990'
      expect(resource4['end']).to eq '2019'
    end
  end
  describe "call_number_display field" do
    it "indexes the call_number_display field" do
      expect(@sample40['call_number_display']).to eq(["Oversize RA566.27 .B7544 2003q"])
    end
    it "returns the call_number_display field with k subfield in the beginning" do
      expect(@record_call_number1['call_number_display']).to eq(["Eng 20Q 6819"])
    end
    it "skips indexing the field if subfields $h and $i and $k are missing" do
      expect(@record_call_number_nil['call_number_display']).to be nil
    end
    it "doesnt have trailing spaces" do
      expect(@record_call_number2['call_number_display']).to eq(["CD- 50000"])
    end
  end

  describe "call_number_browse field" do
    it "indexes the call_number_browse field" do
      expect(@sample40['call_number_browse_s']).to eq([".B7544 2003q Oversize RA566.27"])
    end
    it "returns the call_number_browse field with k subfield at the end and no trailing spaces" do
      record_call_number = @indexer.map_record(fixture_record('9957270023506421'))
      expect(@record_call_number1['call_number_browse_s']).to eq(["6819 Eng 20Q"])
    end
    it "skips indexing the fields if subfields $h and $i and $k are missing" do
      expect(@record_call_number_nil['call_number_browse_s']).to be nil
    end
    it "doesnt have trailing spaces" do
      expect(@record_call_number2['call_number_browse_s']).to eq(["CD- 50000"])
    end
  end

  describe "call_number_locator_display field" do
    it "returns the call_number_locator_display field with no subfield k" do
      expect(@sample40['call_number_locator_display']).to eq([".B7544 2003q"])
    end
  end

  describe "contained_in_s field" do
    it "indexes the 773w of the constituent record" do
      record = @indexer.map_record(fixture_record('9939073273506421'))
      expect(record['contained_in_s']).to eq(["992953283506421"])
    end
  end

  describe 'the language_iana_s field' do
    it 'returns a language value based on the IANA Language Subtag Registry, rejecting invalid codes' do
      expect(@sample1['language_code_s']).to eq(['eng', '|||'])
      expect(@sample1['language_iana_s']).to eq(['en'])
    end

    it 'returns 2 language values based on the IANA Language Subtag Registry' do
      expect(@added_title_246['language_iana_s']).to eq(['ja', 'en'])
    end
  end

  describe 'the isbn_display field' do
    it 'has more than one q subfields' do
      expect(@sample35['isbn_display']).to eq(["9780816695706 (hardcover : alkaline paper)", "0816695709 (hardcover : alkaline paper)", "9780816695713 (paperback : alkaline paper)", "0816695717 (paperback : alkaline paper)"])
    end

    it 'has one a subfield' do
      expect(@sample2['isbn_display']).to eq(["0947752196"])
    end

    it 'skips indexing if subfield $a is missing' do
      expect(@sample38['isbn_display']).to eq ["9780429424304 (electronic book)", "0429424302 (electronic book)"]
      expect(@sample38['isbn_display']).not_to include ' (hardcover)'
      expect(@sample39['isbn_display']).to be nil
    end
  end

  describe 'the id field' do
    it 'has exactly 1 value' do
      expect(@sample1['id'].length).to eq 1
    end
  end
  describe 'numeric_id_b' do
    it 'returns desired boolean' do
      expect(@sample1['numeric_id_b'].first).to eq true
      expect(@scsb_nypl['numeric_id_b'].first).to eq false
    end
  end
  describe 'the title_sort field' do
    it 'does not have initial articles' do
      expect(@sample1['title_sort'][0].start_with?('Advanced concepts')).to be_truthy
    end
  end
  describe 'the author_display field' do
    it 'takes from the 100 field' do
      expect(@sample1['author_display'][0]).to eq 'Singh, Digvijai, 1934-'
    end
    it 'shows only 100 field' do
      expect(@sample2['author_display'][0]).to eq 'White, Michael M.'
    end
    it 'shows 110 field' do
      expect(@sample3['author_display'][0]).to eq 'World Data Center A for Glaciology'
    end
  end
  describe 'the author_citation_display field' do
    it 'shows only the 100 a subfield' do
      expect(@sample1['author_citation_display'][0]).to eq 'Singh, Digvijai'
    end
    it 'shows only the 700 a subfield' do
      expect(@sample36['author_citation_display']).to include 'Ishizuka, Harumichi'
    end
  end
  describe 'the title vernacular display' do
    it 'is a single value for scsb records' do
      expect(@scsb_alt_title['title_vern_display'].length).to eq(1)
    end

    it 'is a single value for pul records' do
      expect(@title_vern_display['title_vern_display'].length).to eq(1)
    end
  end
  describe 'publication_place_facet field' do
    it 'maps the 3-digit code in the 008[15-17] to a name' do
      expect(@sample1['publication_place_facet']).to eq ['Michigan']
    end
    it 'maps the 2-digit code in the 008[15-17] to a name' do
      expect(@added_title_246['publication_place_facet']).to eq ['Japan']
    end
  end
  describe 'the pub_citation_display field' do
    it 'shows the the 260 a and b subfields' do
      expect(@sample2['pub_citation_display']).to include 'London: Firethorn Press'
    end
  end
  describe 'notes from record show up in the notes_index' do
    it 'shows tag 500 and 538' do
      expect(@sample34['notes_index']).to include('DVD ; all regions ; Dolby digital.', 'Originally released as documentary films 1956-1971.')
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
    let(:no_date_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [no_date_008, p260], 'leader' => leader)) }
    let(:date_9999_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [date_9999_008, p260], 'leader' => leader)) }
    let(:date_199u_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [date_199u_008, p260], 'leader' => leader)) }
    let(:not_ceased_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [not_ceased_008, p260], 'leader' => leader)) }
    let(:ceased_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [ceased_008, p260], 'leader' => leader)) }
    let(:no_trailing_date_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [ceased_008, p260_complete], 'leader' => leader)) }
    it 'displays 264 tag sorted by indicator2' do
      expect(@sample34['pub_created_display']).to eq ["[Paris] : Les Films de La Pleiade, 1956-1971.", "[Brooklyn, N.Y.] : Icarus Films, [2017]", "Â©1956-1971"]
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
    before do
      @record_cjk = @indexer.map_record(fixture_record('9939238033506421'))
    end
    it 'displays 880 in pub_created_vern_display and subject field' do
      expect(@record_cjk['pub_created_vern_display']).to eq ['[China : s.n.], 清乾隆癸亥 [8年, 1743]']
      expect(@record_cjk['cjk_subject']).to eq ['子部 醫家類 兒科.']
    end
    it 'cjk_all contains 880 fields in a single string' do
      expect(@record_cjk['cjk_all'][0]).to include('葉其蓁. 抱乙子幼科指掌遺藁 : 五卷 / 葉其蓁編輯 ; [葉] 大本述. 幼科指掌.  [China : s.n.], 清乾隆癸亥 [8年, 1743] 子部 醫家類 兒科. ')
    end
    it 'cjk_notes contains 880 fields associated with 5xx fields' do
      expect(@record_cjk['cjk_notes'][0]).to include('乾隆癸亥李大倫"序"言刻書事.')
      expect(@record_cjk['cjk_notes'][0]).not_to include('子部')
    end
  end
  describe 'related_name_json_1display' do
    it 'trims punctuation the same way as author_s facet' do
      rel_names = JSON.parse(@related_names['related_name_json_1display'][0])
      rel_names['Related name'].each { |n| expect(@related_names['author_s']).to include(n) }
    end
    it 'allows multiple roles from single field' do
      rel_names = JSON.parse(@label_i_246['related_name_json_1display'][0])
      expect(rel_names['Film director']).to include('Kim, ToÌ†k-su')
      expect(rel_names['Screenwriter']).to include('Kim, ToÌ†k-su')
    end
  end
  describe 'access_facet' do
    it 'value is in the library for non-electronic records' do
      expect(@sample3['access_facet']).to include 'In the Library'
      expect(@sample3['access_facet']).not_to include 'Online'
    end

    it 'value is online for records where 856 field second indicator is 0' do
      expect(online['access_facet']).to include 'Online'
      expect(online['access_facet']).not_to include 'In the Library'
    end

    it 'value can be both in the library and online when there are multiple holdings' do
      expect(@online_at_library['access_facet']).to include 'Online'
      expect(@online_at_library['access_facet']).to include 'In the Library'
    end

    it 'value include online when record is present in hathi report with permanent access' do
      expect(@hathi_permanent['access_facet']).to contain_exactly('Online', 'In the Library')
      expect(@hathi_permanent['hathi_identifier_s']).to contain_exactly("mdp.39015036879529")
    end
  end

  describe 'holdings_1display' do
    it 'groups holding info into a hash keyed on the mfhd id' do
      @holdings = JSON.parse(@sample37["holdings_1display"][0])
      expect(@holdings.keys).to eq ["22170509880006421", "22170509890006421", "22170509900006421"]
      expect(@holdings['22170509880006421']['location_code']).to eq 'engineer$stacks'
      expect(@holdings['22170509890006421']['location_code']).to eq 'lewis$stacks'
      expect(@holdings['22170509900006421']['location_code']).to eq 'firestone$stacks'
      expect(@holdings['22170509890006421']['location_note']).to eq ['To borrow this ebook, please request an iPad from the circulation desk at Lewis Library']
    end
    it "does not include an empty call number field" do
      @holdings = JSON.parse(@record_call_number_nil["holdings_1display"][0])
      expect(@holdings['22100565840006421']['call_number']).to be nil
      expect(@holdings['22100565840006421']['call_number_browse']).to be nil
    end
    it "includes a call number field when there is a subfield with a value" do
      @holdings = JSON.parse(@sample40["holdings_1display"][0])
      expect(@holdings['22172120500006421']['call_number']).to eq ".B7544 2003q Oversize RA566.27"
      expect(@holdings['22172120500006421']['call_number_browse']).to eq ".B7544 2003q Oversize RA566.27"
    end
  end

  describe 'electronic_access_1display' do
    it 'holding 856s are excluded from electronic_access_1display' do
      @electronic_access_1display = JSON.parse(@sample37["electronic_access_1display"].to_s)
      expect(@electronic_access_1display).not_to include('holding_record_856s')
    end
  end

  describe 'excluding locations from library facet' do
    let(:location_code_s) { current_record['location_code_s'] }
    let(:location_display) { current_record['location_display'] }
    let(:location) { current_record['location'] }

    context 'when there are location codes which do not map to the labels' do
      let(:id) { '99276293506421_invalid_location' }

      it 'when location codes that do not map to labels' do
        expect(current_record['location_code_s']).to include 'invalidcode'
        expect(current_record['location_display']).to be_nil
        expect(current_record['location']).to be_nil
      end
    end
  end
  describe 'location facet values for Recap items' do
    it 'marquand recap items have a location value of marquand and recap' do
      expect(@added_title_246['location_display']).to eq ['Remote Storage: Marquand Library use only']
      expect(@added_title_246['location']).to eq ['ReCAP']
    end
    it 'non-rare recap items only have a location value of recap' do
      expect(@online_at_library['location_display']).to include 'Mudd Off-Site Storage: Contact mudd@princeton.edu'
      expect(@online_at_library['location']).to include 'ReCAP'
      expect(@online_at_library['location']).not_to include 'Mudd Manuscript Library'
    end
  end

  let(:record_fixture_path) { fixture_record(id) }
  let(:current_record) { @indexer.map_record(record_fixture_path) }

  describe 'including libraries and codes in advanced_location_s facet' do
    let(:id) { '9992320213506421' }
    let(:location_code_s) { current_record['location_code_s'] }
    let(:advanced_location_s) { current_record['advanced_location_s'] }

    it 'lewis library included with lewis code' do
      expect(current_record).to include('advanced_location_s')
      expect(advanced_location_s).to include('lewis$stacks')
      expect(advanced_location_s).to include('Lewis Library')
    end

    it 'library is excluded from location_code_s' do
      expect(current_record).to include('advanced_location_s')
      expect(location_code_s).to include('lewis$stacks')
      expect(location_code_s).not_to include('Lewis Library')
    end
  end
  describe 'other_title_display array 246s included' do
    it 'regardless of 2nd indicator value' do
      expect(@added_title_246['other_title_display']).to include 'Bi ni itaru yamai'
      expect(@added_title_246['other_title_display']).to include 'Morimura Yasumasa, the sickness unto beauty'
      expect(@added_title_246['other_title_display']).to include 'Sickness unto beauty'
    end
    it 'when no 2nd indicator' do
      expect(@other_title_246['other_title_display']).to include 'Episcopus, civitas, territorium'
    end
    it 'excludes other title when subfield $i is present' do
      expect(@label_i_246['other_title_display']).to be_nil
    end
  end
  describe 'other_title_1display 246s hash' do
    it 'excludes titles with 2nd indicator labels' do
      expect(@added_title_246['other_title_1display']).to be_nil
    end
    it 'uses label from $i when available' do
      other_title_hash = JSON.parse(@label_i_246['other_title_1display'].first)
      expect(other_title_hash['English title also known as']).to include 'Dad for rent'
    end
  end
  describe 'multiple 245s' do
    it 'only uses first 245 in single-valued title_display field' do
      expect(@sample3['title_display'].length).to eq 1
    end
  end
  describe 'multiformat record' do
    it 'manuscript book includes both formats, manuscript first' do
      expect(@manuscript_book['format']).to eq ['Manuscript', 'Book']
    end
  end
  describe '852 $b $c location code processing' do
    it 'supports multiple location codes in separate 852s' do
      record = @indexer.map_record(fixture_record('9992320213506421'))
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
      no_440 = @indexer.map_record(MARC::Record.new_from_hash('fields' => [t400], 'leader' => leader))
      expect(no_440['series_title_index']).to include('TITLE')
    end
    it 'includes 400 and 440 field for series_title_index field' do
      yes_440 = @indexer.map_record(MARC::Record.new_from_hash('fields' => [t400, t440], 'leader' => leader))
      expect(yes_440['series_title_index']).to match_array(['TITLE', 'John 1492'])
    end
    it 'excludes series_title_index field when no matching values' do
      expect(@sample1['series_title_index']).to be_nil
    end
  end

  describe 'both a and t must be present in linked title field' do
    let(:t760) { { "760" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "t" => "TITLE" }] } } }
    let(:a762) { { "762" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "NAME" }] } } }
    let(:at765) { { "765" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "Both" }, { "t" => "name and title" }] } } }
    let(:linked_record) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [t760, a762, at765], 'leader' => leader)) }

    it 'only includes 765at' do
      expect(linked_record['linked_title_s']).to match_array(['Both name and title'])
    end

    it 'linked title field included in name-title browse' do
      expect(linked_record['name_title_browse_s']).to include('Both name and title')
    end
  end

  describe '#related_record_info_display' do
    let(:i776) { { "776" => { "ind1" => "", "ind2" => "", "subfields" => [{ "i" => "Test description" }] } } }
    let(:linked_record) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [i776], 'leader' => leader)) }

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
    let(:uniform_title) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [n100, n100_vern, t240, t240_vern, t245, t245_vern], 'leader' => leader)) }
    let(:no_uniform_title) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [n100, n100_vern, t245, t245_vern], 'leader' => leader)) }

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
    let(:record) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [s490, s830, s440], 'leader' => leader)) }

    it '490s are not included when they are covered by another series field' do
      expect(record['series_display']).to match_array(['Series title.', 'The Series'])
    end

    it 'matches for other works within series ignore non-filing characters, trim punctuation' do
      expect(record['more_in_this_series_t']).to match_array(['Series title', 'Series'])
    end
  end
  describe 'senior thesis 502 note' do
    let(:senior_thesis_502) { { "502" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => "Thesis (Senior)-Princeton University" }] } } }
    let(:senior_thesis_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [senior_thesis_502], 'leader' => leader)) }
    let(:whitespace_502) { { "502" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => "Thesis (Senior)  -- Princeton University" }] } } }
    let(:senior_thesis_whitespace) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [whitespace_502], 'leader' => leader)) }
    let(:subfield_bc_502) { { "502" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "b" => "Senior" }, { "c" => "Princeton University" }] } } }
    let(:thesis_bc_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [subfield_bc_502], 'leader' => leader)) }

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
    let(:subject_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [s650_lcsh, s650_sk, s650_exclude], 'leader' => leader)) }

    it 'include the sk and lc subjects in separate fields, exlcude other subject types' do
      expect(subject_marc['lc_subject_display']).to match_array(['LC Subject'])
      expect(subject_marc['subject_unstem_search']).to match_array(['LC Subject'])
      expect(subject_marc['siku_subject_display']).to match_array(['Siku Subject'])
      expect(subject_marc['siku_subject_unstem_search']).to match_array(['Siku Subject'])
    end
  end
  describe 'form_genre_display' do
    subject(:form_genre_display) { @indexer.map_record(marc_record) }
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

  describe 'recap_notes_display' do
    it "skips indexing for Princeton Recap records" do
      expect(@recap_record["recap_notes_display"]).to be nil
    end
    it "Indexes N - O, if not a private/shared SCSB record" do
      expect(@scsb_nypl["recap_notes_display"]).to eq ["N - O"]
    end
  end
end
