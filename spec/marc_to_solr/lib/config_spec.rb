require 'rails_helper'

describe 'From traject_config.rb' do
  let(:leader) { '1234567890' }

  def fixture_record(fixture_name)
    f = File.expand_path("../../../fixtures/marc_to_solr/#{fixture_name}.mrx", __FILE__)
    @indexer.reader!(f).first
  end

  def fixture_alma_record(fixture_name)
    f = File.expand_path("../../../fixtures/marc_to_solr/alma/#{fixture_name}.mrx", __FILE__)
    @indexer.reader!(f).first
  end

  before(:all) do
    stub_request(:get, "https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000")

    @indexer = IndexerService.build
    @sample1 = @indexer.map_record(fixture_record('sample1'))
    @sample2 = @indexer.map_record(fixture_record('sample2'))
    @sample3 = @indexer.map_record(fixture_record('sample3'))
    @sample34 = @indexer.map_record(fixture_record('sample34'))
    @sample35 = @indexer.map_record(fixture_record('sample35'))
    @sample36 = @indexer.map_record(fixture_record('8181849'))
    @manuscript_book = @indexer.map_record(fixture_record('sample17'))
    @added_title_246 = @indexer.map_record(fixture_record('sample18'))
    @related_names = @indexer.map_record(fixture_record('sample27'))
    @label_i_246 = @indexer.map_record(fixture_record('sample28'))
    @online_at_library = @indexer.map_record(fixture_record('sample29'))
    @online = @indexer.map_record(fixture_record('sample30'))
    # @elf2 = @indexer.map_record(fixture_record('elf2'))
    @other_title_246 = @indexer.map_record(fixture_record('7910599'))
    @title_vern_display = @indexer.map_record(fixture_record('4854502'))
    @scsb_journal = @indexer.map_record(fixture_record('scsb_nypl_journal'))
    @scsb_alt_title = @indexer.map_record(fixture_record('scsb_cul_alt_title'))
    ENV['RUN_HATHI_COMPARE'] = 'true'
    @hathi_present = @indexer.map_record(fixture_record('1590302'))
    @hathi_permanent = @indexer.map_record(fixture_record('1459166'))
    ENV['RUN_HATHI_COMPARE'] = ''
  end

  describe "alma loading" do
    it "can map an alma record" do
      record = @indexer.map_record(fixture_alma_record('99211662100521'))
    end
  end
  describe 'the cataloged_date from publishing job' do
    describe "the date cataloged facets" do
      context "When the record has 876d and 951w fields" do
        it "will index the 876d field" do
          expect(fixture_alma_record('99211662100521')['951']['w']).to be_truthy
          expect(fixture_alma_record('99211662100521')['876']['d']).to be_truthy
          expect(fixture_alma_record('99211662100521')['950']['b']).to be_truthy
          record = @indexer.map_record(fixture_alma_record('99211662100521'))
          expect(Time.parse(record['cataloged_tdt'].first)).to eq Time.parse(fixture_alma_record('99211662100521')['876']['d']).utc
        end
      end
      context "When the record has only a 950b field" do
        it "will index the 950b field" do
          expect(fixture_alma_record('991330600000541')['950']['b']).to be_truthy
          expect(fixture_alma_record('991330600000541')['876']).to be_falsey
          expect(fixture_alma_record('991330600000541')['951']).to be_falsey
          record = @indexer.map_record(fixture_alma_record('991330600000541'))
          expect(Time.parse(record['cataloged_tdt'].first)).to eq Time.parse(fixture_alma_record('991330600000541')['950']['b']).utc
        end
      end

      context "When the record fails to parse the time" do
        it "logs the error and moves on" do
          allow(Time).to receive(:parse).and_raise(ArgumentError)
          expect { @indexer.map_record(fixture_alma_record('991330600000541')) }.not_to raise_error
        end
      end
    end

    context "When it is a SCSB partner record" do
      it "does not have a date cataloged facet" do
        expect(@scsb_journal['cataloged_tdt']).to be_nil
      end
    end
    context "When it is an eletronic record" do
      it "will index the 951w field" do
        expect(fixture_record('electronic')['951']['w']).to be_truthy
        expect(fixture_record('electronic')['876']).to be_falsey
        expect(fixture_record('electronic')['950']).to be_truthy
        record = @indexer.map_record(fixture_record('electronic'))
        expect(Time.parse(record['cataloged_tdt'].first)).to eq Time.parse(fixture_record('electronic')['951']['w']).utc
      end
    end
  end

  describe "call_number_display field" do
    it "returns the call_number_display field with k subfield at the end" do
      record = @indexer.map_record(fixture_alma_record('9957270023506421'))
      expect(record['call_number_display']).to eq(["6819 Eng 20Q"])
    end
  end

  describe "call_number_browse field" do
    it "returns the call_number_browse field with k subfield at the end" do
      record = @indexer.map_record(fixture_alma_record('9957270023506421'))
      expect(record['call_number_browse_s']).to eq(["6819 Eng 20Q"])
    end
  end

  describe "contained_in_s field" do
    it "indexes the 773w of the constituent record" do
      record = @indexer.map_record(fixture_alma_record('9939073273506421'))
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
  end

  describe 'the id field' do
    it 'has exactly 1 value' do
      expect(@sample1['id'].length).to eq 1
    end
  end
  describe 'numeric_id_b' do
    it 'returns desired bool' do
      expect(@sample1['numeric_id_b'].first).to eq true
      expect(@scsb_journal['numeric_id_b'].first).to eq false
    end
  end
  describe 'the title_sort field' do
    it 'does not have initial articles' do
      expect(@sample1['title_sort'][0].start_with?('advanced concepts')).to be_truthy
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
      expect(@sample2['author_citation_display']).to include 'Jones, Mary'
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
      expect(@sample34['notes_index']).to include('DVD ; all regions ; Dolby digital.', '"Digitized and restored in 2K with the support of the Centre National du Cinéma."')
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
      expect(@sample34['pub_created_display']).to eq ["[Paris] : Les Films de La Pleiade, 1956-1971.", "[Brooklyn, N.Y.] : Icarus Films, [2017]", "©1956-1971"]
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
    it 'displays 880 in pub_created_vern_display and subject field' do
      expect(@sample36['pub_created_vern_display']).to eq ['東京 : 勉誠出版, 2014.']
      expect(@sample36['cjk_subject']).to eq ['石塚晴通']
    end
    it 'cjk_all contains 880 fields in a single string' do
      expect(@sample36['cjk_all'][0]).to include('東京 : 勉誠出版')
      expect(@sample36['cjk_all'][0]).to include('石塚晴通')
    end
    it 'cjk_notes contains 880 fields associated with 5xx fields' do
      expect(@sample36['cjk_notes'][0]).to include('蘭臺')
      expect(@sample36['cjk_notes'][0]).not_to include('石塚晴通')
    end
  end
  describe 'related_name_json_1display' do
    let(:rel_names) { JSON.parse(@related_names['related_name_json_1display'][0]) }
    it 'trims punctuation the same way as author_s facet' do
      rel_names['Related name'].each { |n| expect(@related_names['author_s']).to include(n) }
    end
    it 'allows multiple roles from single field' do
      expect(rel_names['Editor']).to include('Someone')
      expect(rel_names['Painter']).to include('Someone')
    end
  end
  describe 'access_facet' do
    it 'value is in the library for all non-online holding locations' do
      expect(@sample3['location_code_s'][0]).to eq 'lewis$doc' # Lewis Library
      expect(@sample3['access_facet']).to include 'In the Library'
      expect(@sample3['access_facet']).not_to include 'Online'
    end
    # TODO: Replace with Alma
    xit 'value is at the library for elf2 holding location' do
      expect(@elf2['location_code_s'][0]).to eq 'elf2'
      expect(@elf2['access_facet']).not_to include 'Online'
      expect(@elf2['access_facet']).to include 'In the Library'
    end
    it 'value is online for all other elf holding locations' do
      expect(@online['location_code_s'][0]).to eq 'online$elf1'
      expect(@online['access_facet']).to include 'Online'
      expect(@online['access_facet']).not_to include 'In the Library'
    end
    it 'value can be both in the library and online when there are multiple holdings' do
      expect(@online_at_library['location_code_s']).to include 'online$elf1'
      expect(@online_at_library['location_code_s']).to include 'recap$ph'
      expect(@online_at_library['access_facet']).to include 'Online'
      expect(@online_at_library['access_facet']).to include 'In the Library'
    end
    it 'value include hathi locations when record is present in hathi report' do
      expect(@hathi_present['location_code_s']).to contain_exactly('lewis$stacks')
      expect(@hathi_present['access_facet']).to contain_exactly('Temporary Digital Access', 'Online', 'In the Library')
      expect(@hathi_present['hathi_identifier_s']).to contain_exactly("mdp.39015002162876")
    end
    it 'value include online when record is present in hathi report with permanent access' do
      expect(@hathi_permanent['location_code_s']).to contain_exactly('rcppa')
      expect(@hathi_permanent['access_facet']).to contain_exactly('Online', 'In the Library')
      expect(@hathi_permanent['hathi_identifier_s']).to contain_exactly("mdp.39015036879529")
    end
  end
  describe 'holdings_1display' do
    before(:all) do
      marcxml = fixture_record('7617477')
      @solr_hash = @indexer.map_record(marcxml)
      @holding_block = JSON.parse(@solr_hash['holdings_1display'].first)
      holdings_file = File.expand_path("../../../fixtures/marc_to_solr/7617477-holdings.json", __FILE__)
      holdings = JSON.parse(File.read(holdings_file))
      @holding_records = []
      holdings.each { |h| @holding_records << MARC::Record.new_from_hash(h) }
    end
    it 'groups holding info into a hash keyed on the mfhd id' do
      @holding_records.each do |holding|
        holding_id = holding['001'].value
        expect(@holding_block[holding_id]['location_code']).to include(holding['852']['b'])
        expect(@holding_block[holding_id]['location_note']).to include(holding['852']['z'])
      end
    end

    it 'includes holding 856s keyed on mfhd id' do
      @holding_records.each do |holding|
        holding_id = holding['001'].value
        electronic_access = @holding_block[holding_id]['electronic_access']
        expect(electronic_access[holding['856']['u']]).to include(holding['856']['z'])
      end
    end

    it 'holding 856s are excluded from electronic_access_1display' do
      electronic_access = JSON.parse(@solr_hash['electronic_access_1display'].first)
      expect(electronic_access).not_to include('holding_record_856s')
    end
  end
  describe 'excluding locations from library facet' do
    it 'when location is online' do
      expect(@online['location_code_s']).to include 'online$elf1'
      expect(@online['location_display']).to include 'Electronic Access - Electronic Access - elf1 Internet Resources'
      expect(@online['location']).to eq ['Electronic Access']
    end

    it 'when location codes that do not map to labels' do
      expect(@sample1['location_code_s']).to include 'invalidcode'
      expect(@sample1['location_display']).to be_nil
      expect(@sample1['location']).to be_nil
    end
  end
  describe 'location facet values for Recap items' do
    it 'marquand recap items have a location value of marquand and recap' do
      expect(@added_title_246['location_display']).to eq ['ReCAP - ReCAP - rcppj RECAP Marq. Lib.']
      expect(@added_title_246['location']).to eq ['ReCAP', 'Marquand Library']
    end
    it 'non-rare recap items only have a location value of recap' do
      expect(@online_at_library['location_display']).to include 'Electronic Access - Electronic Access - elf1 Internet Resources'
      expect(@online_at_library['location']).to include 'ReCAP'
      expect(@online_at_library['location']).not_to include 'Mudd Manuscript Library'
    end
  end
  describe 'including libraries and codes in advanced_location_s facet' do
    it 'lewis library included with lewis code' do
      expect(@sample3['advanced_location_s']).to include 'lewis$doc'
      expect(@sample3['advanced_location_s']).to include 'Lewis Library'
    end
    # TODO: Replace with Alma
    xit 'online is included' do
      expect(@elf2['advanced_location_s']).to include 'elf2'
      expect(@elf2['advanced_location_s']).to include 'Online'
    end
    it 'library is excluded from location_code_s' do
      expect(@sample3['location_code_s']).to include 'lewis$doc'
      expect(@sample3['location_code_s']).not_to include 'Lewis Library'
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
  describe '852 $b location processing' do
    let(:extra_b_record) { fixture_record('sample27') }
    let(:single_b)  { extra_b_record.fields('852')[0]['b'] }
    let(:extra_b) { extra_b_record.fields('852')[1].map { |f| f.value if f.code == 'b' }.compact }

    it 'supports multiple location codes in separate 852s' do
      expect(@related_names['location_code_s']).to include(single_b, extra_b.first)
    end
    it 'only includes the first $b within a single tag' do
      expect(@related_names['location_code_s']).not_to include(extra_b.last)
    end
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
end
