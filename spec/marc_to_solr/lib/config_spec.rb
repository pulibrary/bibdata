require 'rails_helper'

describe 'From traject_config.rb', indexing: true do
  let(:leader) { '1234567890' }
  let(:online) { @indexer.map_record(fixture_record('9990889283506421')) }

  def fixture_record(fixture_name, indexer: @indexer)
    f = File.expand_path("../../../fixtures/marc_to_solr/#{fixture_name}.mrx", __FILE__)
    indexer.reader!(f).first
  end

  context "valid records" do
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
      @sample41 = @indexer.map_record(fixture_record('99106471643506421'))
      @sample42 = @indexer.map_record(fixture_record('9939339473506421'))
      @sample43 = @indexer.map_record(fixture_record('9935444363506421'))
      @sample44 = @indexer.map_record(fixture_record('9913811723506421'))
      @record_temporary_location = @indexer.map_record(fixture_record('99124695833506421'))
      @record_temporary_location_v2 = @indexer.map_record(fixture_record('99124695833506421_custom_holdings'))
      @record_res3hr = @indexer.map_record(fixture_record('99125379706706421'))
      @indigenous_studies = @indexer.map_record(fixture_record('9922655623506421'))
      @change_the_subject1 = @indexer.map_record(fixture_record('15274230460006421'))
      @added_custom_951 = @indexer.map_record(fixture_record('99299653506421_custom_951')) # custom marc record with an extra 951 field
      @record_call_number1 = @indexer.map_record(fixture_record('9957270023506421'))
      @record_call_number2 = @indexer.map_record(fixture_record('99103141233506421'))
      @record_call_number_nil = @indexer.map_record(fixture_record('99102664603506421'))
      @record_no_call_number = @indexer.map_record(fixture_record('99102664603506421_no_call_number'))
      @manuscript_book = @indexer.map_record(fixture_record('9959060243506421'))
      @added_title_246 = @indexer.map_record(fixture_record('9930602883506421'))
      @related_names = @indexer.map_record(fixture_record('9919643053506421'))
      @label_i_246 = @indexer.map_record(fixture_record('9990315453506421'))
      @online_at_library = @indexer.map_record(fixture_record('9979160443506421'))
      @other_title_246 = @indexer.map_record(fixture_record('9979105993506421'))
      @title_vern_display = @indexer.map_record(fixture_record('9948545023506421'))
      @scsb_nypl = @indexer.map_record(fixture_record('SCSB-8157262'))
      @scsb_alt_title = @indexer.map_record(fixture_record('scsb_cul_alt_title'))
      @scsb_private = @indexer.map_record(fixture_record('scsb_harvard_private'))
      @scsb_committed = @indexer.map_record(fixture_record('scsb_harvard_committed'))
      @scsb_uncommittable = @indexer.map_record(fixture_record('scsb_harvard_uncommittable'))
      @recap_record = @indexer.map_record(fixture_record('994081873506421'))
      @inactive_electronic_portfolio = @indexer.map_record(fixture_record('99123430173506421_electronic_inactive'))
      @custom_inactive_electronic_portfolio = @indexer.map_record(fixture_record('99125267333206421_custom_inactive951'))
      @electronic_portfolio_embargo = @indexer.map_record(fixture_record('99125105174406421'))
      @electronic_portfolio_active_no_collection_name = @indexer.map_record(fixture_record('9995002873506421'))
      @electronic_portfolio_with_notes = @indexer.map_record(fixture_record('9934701143506421'))
      @multilanguage_iana = @indexer.map_record(fixture_record('99125428133406421_multiple_languages'))
      @sign_language_iana = @indexer.map_record(fixture_record('99106137213506421_sign_language'))
      @italian_language_iana = @indexer.map_record(fixture_record('99125428126306421_italian'))
      @undetermined_language_iana = @indexer.map_record(fixture_record('99125420871206421_undetermined'))
      @no_linguistic_language_iana = @indexer.map_record(fixture_record('99125428446106421_no_linguistic_content'))
      @holding_no_items = @indexer.map_record(fixture_record('99125441441106421')) # also if you want use 99106480053506421
      @electronic_no_852 = @indexer.map_record(fixture_record('99125406065106421'))
      @holdings_with_and_no_items = @indexer.map_record(fixture_record('99122643653506421'))
      @local_subject_heading = @indexer.map_record(fixture_record('local_subject_heading'))
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
        expect(@scsb_nypl["location_display"]).to eq ["Remote Storage"]
      end
    end
    describe "holdings" do
      it "can index holdings" do
        record = @indexer.map_record(fixture_record('9992320213506421'))
        holdings = JSON.parse(record["holdings_1display"][0])
        holding_1 = holdings["22685775490006421"]
        holding_2 = holdings["22685775470006421"]
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
        context "When the record has 950, 876 and 951 fields" do
          it "will index the oldest 876d field" do
            marc_record = fixture_record('99299653506421_custom_951')
            fields_876_sorted = alma_876(marc_record).map { |f| f['d'] }.sort
            expect(marc_record['876']['d']).to be_truthy
            expect(marc_record['951']['w']).to be_truthy
            expect(marc_record['950']['b']).to be_truthy
            expect(Time.parse(@added_custom_951['cataloged_tdt'].first)).to eq Time.parse(fields_876_sorted.first).utc
          end
        end
        context "When the record has only a 950b field" do
          it "will index the 950b field" do
            record = fixture_record('9939339473506421')
            expect(record['950']['b']).to be_truthy
            expect(record['876']).to be_falsey
            expect(record['951']).to be_falsey
            expect(Time.parse(@sample42['cataloged_tdt'].first)).to eq Time.parse(record['950']['b']).utc
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
      context "When it is an electronic record" do
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
        expect(nature['notes']).to be_empty

        # Date range with explicit start and no end date
        expect(nature['start']).to eq '1869'
        expect(nature['end']).to eq 'latest'

        # Date range with explicit start and end
        expect(ebsco['start']).to eq '1997'
        expect(ebsco['end']).to eq '2015'

        # electronic_portfolio_s should not include non alma 951(s).
        expect(resource1).to be nil
        expect(resource2).to be nil
        expect(resource3).to be nil
        expect(resource4).to be nil
      end
      it "takes into account the 954 embargo field" do
        portfolios = @electronic_portfolio_embargo['electronic_portfolio_s'].map { |p| JSON.parse(p) }
        portfolio1 = portfolios.find { |p| p['title'] == 'EBSCOhost Academic Search Ultimate' }
        portfolio2 = portfolios.find { |p| p['title'] == 'Taylor & Francis Medical Library' }

        # Date range with greater than or equal to embargo
        expect(portfolio1['start']).to eq '2001'
        expect(portfolio1['end']).to eq '2021'

        expect(portfolio2['start']).to eq '1997'
        expect(portfolio2['end']).to eq 'latest'
      end
      it "will not index an inactive electronic_portfolio" do
        expect(@inactive_electronic_portfolio['electronic_portfolio_s']).to be nil
      end
      it "finds collection notes" do
        portfolio = @electronic_portfolio_with_notes['electronic_portfolio_s'].map { |p| JSON.parse(p) }
        expect(portfolio.any? { |hash| hash['notes'].include? 'scroll down and click either on "CCSDS Recommendations (Blue Books)" or on "CCSDS Reports (Green Books)" to display its clickable contents' }).to be true
      end
      describe 'with active and inactive portfolio' do
        before do
          @active_portfolios1 = @custom_inactive_electronic_portfolio['electronic_portfolio_s'].map { |p| JSON.parse(p) }
        end
        it 'will index the active portfolio' do
          expect(@active_portfolios1.any? { |hash| hash['title'] == "SciTech Premium Collection" }).to be true
          expect(@active_portfolios1.any? { |hash| hash["url"] == "https://na05.alma.exlibrisgroup.com/view/uresolver/01PRI_INST/openurl?u.ignore_date_coverage=true&portfolio_pid=53788872140006421&Force_direct=true" }).to be true
        end
        it "will not index the inactive portfolio" do
          expect(@active_portfolios1).not_to include '53821583960006421'
        end
      end
      describe 'active portfolio not part of a collection' do
        before do
          @active_portfolios2 = @electronic_portfolio_active_no_collection_name['electronic_portfolio_s'].map { |p| JSON.parse(p) }
        end
        it "has title: Online content" do
          expect(@active_portfolios2[0]['title']).to eq 'Online Content'
        end
      end
    end
    describe "call_number_display field" do
      it "indexes the call_number_display field" do
        expect(@sample40['call_number_display']).to eq(["Oversize RA566.27 .B7544 2003q"])
      end
      it "returns the call_number_display field with k subfield in the beginning" do
        expect(@record_call_number1['call_number_display']).to eq(["Eng 20Q 6819"])
      end
      it "returns an array of call_number_display values" do
        expect(@sample43['call_number_display']).to eq(["01.XIII.19", "JV6225 .R464 2001"])
        expect(@sample44['call_number_display']).to eq(["0230.317", "Z209.N56 E2 1928", "Pamphlets", "2006-1620N"])
      end
      it "skips indexing the field if subfields $h and $i and $k are missing" do
        expect(@record_call_number_nil['call_number_display']).to be nil
      end
      it "doesnt have trailing spaces" do
        expect(@record_call_number2['call_number_display']).to eq(["CD- 50000"])
      end
      it 'returns the enrichment call_number_display with k in front' do
        expect(@sample41['call_number_display']).to eq(["A Middle 30/Drawer 11/GC024/Full Folio/20th-21st c./Artists A GA 2015.00160"])
      end
      it 'returns the call_number_display for a SCSB record' do
        expect(@scsb_nypl['call_number_display']).to contain_exactly("JSM 95-217", "JSM 95-216")
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
      it "returns an array of call_number_browse_s values" do
        expect(@sample43['call_number_browse_s']).to eq(["01.XIII.19", "JV6225 .R464 2001"])
        expect(@sample44['call_number_browse_s']).to eq(["0230.317", "Z209.N56 E2 1928", "Pamphlets", "2006-1620N"])
      end
      it "skips indexing the field if subfields $h and $i and $k are missing" do
        expect(@record_call_number_nil['call_number_browse_s']).to be nil
      end
      it "doesnt have trailing spaces" do
        expect(@record_call_number2['call_number_browse_s']).to eq(["CD- 50000"])
      end
      it 'returns the enrichment call_number_browse with k at the end' do
        expect(@sample41['call_number_browse_s']).to eq(["GA 2015.00160 A Middle 30/Drawer 11/GC024/Full Folio/20th-21st c./Artists A"])
      end
      it 'returns the call_number_browse_s for a SCSB record' do
        expect(@scsb_nypl['call_number_browse_s']).to contain_exactly("JSM 95-217", "JSM 95-216")
      end
    end

    describe "call_number_locator_display field" do
      it "returns the call_number_locator_display field with no subfield k" do
        expect(@sample40['call_number_locator_display']).to eq([".B7544 2003q"])
      end
      it "returns an array of call_number_locator_display values with no subfield k" do
        expect(@sample43['call_number_locator_display']).to eq(["01.XIII.19", "JV6225 .R464 2001"])
      end
      it "skips indexing the field if subfields $h and $i are missing" do
        expect(@record_call_number_nil['call_number_locator_display']).to be nil
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
        expect(@sample1['language_code_s']).to eq(['eng'])
        expect(@sample1['language_iana_s']).to eq(['en'])
      end

      it 'returns the first value from the IANA Language Subtag Registry' do
        # record has ["jpn", "jpneng"]
        expect(@added_title_246['language_iana_s']).to eq(['ja'])
      end

      it 'returns the language value of a multilanguage document' do
        # a multilanguage has value 008 mul. Skip this value and look 041
        expect(@multilanguage_iana['language_iana_s']).to eq ["en"] # ISO_639 for 041$a
      end

      it 'returns the language value of a sign language document' do
        expect(@sign_language_iana['language_iana_s']).to eq ["zh"] # ISO_639 for 041$a chi
      end

      it 'defaults to "en" when the language value is undetermined' do
        expect(@undetermined_language_iana['language_iana_s']).to eq ["en"]
      end

      it 'defaults to "en" for a record with no linguistic content' do
        expect(@no_linguistic_language_iana['language_iana_s']).to eq ["en"]
      end

      it 'returns language value "it" for an italian record' do
        expect(@italian_language_iana['language_iana_s']).to eq ["it"]
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
        expect(@holdings['22690128630006421']['call_number']).to be nil
        expect(@holdings['22690128630006421']['call_number_browse']).to be nil
      end
      it "can index when there's no 852 call number fields (khij)" do
        @holdings = JSON.parse(@record_no_call_number["holdings_1display"][0])
        expect(@holdings['22100565840006421']['call_number']).to be nil
        expect(@holdings['22100565840006421']['call_number_browse']).to be nil
      end
      it "includes a call number field when there is a subfield with a value" do
        @holdings = JSON.parse(@sample40["holdings_1display"][0])
        expect(@holdings['22666524470006421']['call_number']).to eq ".B7544 2003q Oversize RA566.27"
        expect(@holdings['22666524470006421']['call_number_browse']).to eq ".B7544 2003q Oversize RA566.27"
      end
      it "indexes permanent and temporary locations" do
        @holdings = JSON.parse(@record_temporary_location["holdings_1display"][0])
        expect(@holdings['22745884920006421']['location_code']).to eq "lewis$stacks"
        expect(@holdings['22745884920006421']["items"][0]['id']).to eq "23745884910006421"
        expect(@holdings["22745884920006421"]["items"].count).to eq 1
        expect(@holdings["lewis$res"]["location_code"]).to eq "lewis$res"
        expect(@holdings["lewis$res"]["current_location"]).to eq "Course Reserve"
        expect(@holdings["lewis$res"]["current_library"]).to eq "Lewis Library"
        expect(@holdings["lewis$res"]["items"].count).to eq 1
        expect(@holdings["lewis$res"]["items"][0]["id"]).to eq '23898873500006421'
        expect(@holdings["lewis$res"]["items"][0]["holding_id"]).to eq '22745884920006421'
        ## custom fixture @record_temporary_location_v2 with permanent and temporary locations
        @holdings_v2 = JSON.parse(@record_temporary_location_v2["holdings_1display"][0])
        expect(@holdings_v2["22745884920006421"]["items"].count).to eq 2
        expect(@holdings_v2["22745884920006421"]["items"][0]["id"]).to eq '23745884910006421'
        expect(@holdings_v2["22745884920006421"]["items"][1]["id"]).to eq '23799884910006421'
        expect(@holdings_v2["lewis$res"]["items"].count).to eq 3
        expect(@holdings_v2["lewis$res"]["items"][0]["id"]).to eq '23898873500006421'
        expect(@holdings_v2["lewis$res"]["items"][1]["id"]).to eq '23888873500006421'
        expect(@holdings_v2["lewis$res"]["items"][2]["id"]).to eq '23998873500006421'
      end
      it "indexes the permanent holding when there are no items (876)" do
        @holdings = JSON.parse(@holding_no_items["holdings_1display"][0])
        expect(@holdings['22537847690006421']['location_code']).to eq 'rare$ex'
        expect(@holdings['22537847690006421']['call_number_browse']).to eq '3400.899'
        expect(@holdings['22537847690006421']['items']).to be_falsey
      end
      it 'if there is no 852 it will have no holdings' do
        expect(@electronic_no_852["holdings_1display"]).to be_falsey
      end
      it 'indexes holdings with items' do
        @holdings = JSON.parse(@holdings_with_and_no_items['holdings_1display'][0])
        expect(@holdings['22543249620006421']['items'].count).to eq 1
        expect(@holdings['22543249680006421']['items'].count).to eq 1
        expect(@holdings['lewis$res']['items'].count).to eq 4
        expect(@holdings['22543249700006421']).to be_falsey # items from this holding are in the temporary location lews$res
        expect(@holdings['22543249720006421']).to be_falsey # items from this holding are in the temporary location lews$res
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
        it 'marquand recap items display as marquand and are in the marquand location facet' do
          expect(@added_title_246['location_display']).to eq ['Remote Storage (ReCAP): Marquand Library Use Only']
          expect(@added_title_246['location']).to eq ['Marquand Library']
        end
        it 'mudd recap items display as mudd and are in the mudd location facet' do
          expect(@online_at_library['location_display']).to include 'Remote Storage (ReCAP): Mudd Library Use Only'
          expect(@online_at_library['location']).to eq ['Mudd Manuscript Library']
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

    context "subject display and unstem fields" do
      let(:s650_sk) { { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Siku Subject" }, { "2" => "sk" }] } } }
      let(:s650_local) { { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Local Subject" }, { "2" => "local" }, { "5" => "NjP" }] } } }
      let(:s650_exclude) { { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Exclude from subject browse" }, { "2" => "bad" }] } } }
      describe 'subject display and unstem fields' do
        let(:s650_lcsh) { { "650" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "LC Subject" }] } } }
        let(:subject_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [s650_lcsh, s650_sk, s650_exclude, s650_local], 'leader' => leader)) }

        it 'include lc subjects and local subjects in the same display field' do
          expect(subject_marc['lc_subject_display']).to match_array(['LC Subject', 'Local Subject'])
        end
        it 'includes siku subjects in separate fields' do
          expect(subject_marc['siku_subject_display']).to match_array(['Siku Subject'])
          expect(subject_marc['siku_subject_unstem_search']).to match_array(['Siku Subject'])
        end
        it 'include lc, siku, and local subjects in separate unstem fields' do
          expect(subject_marc['subject_unstem_search']).to match_array(['LC Subject'])
          expect(subject_marc['local_subject_display']).to match_array(['Local Subject'])
          expect(subject_marc['local_subject_unstem_search']).to match_array(['Local Subject'])
        end

        it 'works using a fixture file' do
          expect(@local_subject_heading['lc_subject_display']).to include("Undocumented immigrants#{SEPARATOR}Europe")
          expect(@local_subject_heading['local_subject_display']).to eq(["Undocumented immigrants#{SEPARATOR}Europe"])
        end
      end
      describe 'subject facet fields' do
        let(:subject_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [s650_sk, s650_exclude, s650_local], 'leader' => leader)) }
        it 'includes siku subjects in subject_facet and subject_topic_facet' do
          expect(subject_marc['subject_facet']).to include('Siku Subject')
          expect(subject_marc['subject_topic_facet']).to include('Siku Subject')
        end

        it 'includes local subjects in subject_facet and subject_topic_facet' do
          expect(subject_marc['subject_facet']).to include('Local Subject')
          expect(subject_marc['subject_topic_facet']).to include('Local Subject')
        end

        it 'does not include other types of subjects in subject_facet or subject_topic_facet' do
          expect(subject_marc['subject_facet']).not_to include('Exclude from subject browse')
          expect(subject_marc['subject_topic_facet']).not_to include('Exclude from subject browse')
        end
      end
      describe 'subject terms augmented for Indigenous Studies' do
        let(:s650_lcsh) { { "650" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "Indians of North America", "z" => "Connecticut." }] } } }
        let(:subject_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [s650_lcsh], 'leader' => leader)) }

        it 'augments the subject terms to add Indigenous Studies' do
          expect(subject_marc["subject_facet"]).to match_array(["Indians of North America#{SEPARATOR}Connecticut", "Indigenous Studies"])
          expect(subject_marc['subject_topic_facet']).to match_array(["Indians of North America", "Connecticut", "Indigenous Studies"])
          expect(subject_marc['lc_subject_display']).to match_array(["Indians of North America#{SEPARATOR}Connecticut", "Indigenous Studies"])
          expect(subject_marc["subject_unstem_search"]).to match_array(["Indians of North America#{SEPARATOR}Connecticut", "Indigenous Studies"])
        end
        it 'works against a fixture' do
          expect(@indigenous_studies["subject_facet"]).to match_array(["Indians of Central America", "Indians of Mexico", "Indians of North America", "Indians of the West Indies", "Indigenous Studies"])
          expect(@indigenous_studies["subject_topic_facet"]).to match_array(["Indians of Central America", "Indians of Mexico", "Indians of North America", "Indians of the West Indies", "Indigenous Studies"])
          expect(@indigenous_studies["lc_subject_display"]).to match_array(["Indians of Central America", "Indians of Mexico", "Indians of North America", "Indians of the West Indies", "Indigenous Studies"])
          expect(@indigenous_studies["subject_unstem_search"]).to match_array(["Indians of Central America", "Indians of Mexico", "Indians of North America", "Indians of the West Indies", "Indigenous Studies"])
        end
      end
      describe 'subject terms changed for Change the Subject' do
        context 'when the subject term is an exact match in $a' do
          let(:s650_lcsh) { { "650" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "Illegal aliens", "z" => "United States." }] } } }
          let(:subject_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [s650_lcsh], 'leader' => leader)) }
          it 'changes the subject term in display fields, but includes both old and new in search fields' do
            expect(subject_marc["subject_facet"]).to match_array(["Undocumented immigrants#{SEPARATOR}United States"])
            expect(subject_marc['subject_topic_facet']).to match_array(["Undocumented immigrants", "United States"])
            expect(subject_marc['lc_subject_display']).to match_array(["Undocumented immigrants#{SEPARATOR}United States"])
            expect(subject_marc["subject_unstem_search"]).to match_array(["Illegal aliens#{SEPARATOR}United States", "Undocumented immigrants#{SEPARATOR}United States"])
          end
          it 'works against a fixture' do
            corrected_subjects_compound = [
              "Undocumented immigrants—United States",
              "Emigration and immigration law—United States",
              "Emigration and immigration—Religious aspects—Christianity",
              "Political theology—United States",
              "Religion and state—United States",
              "Christianity and law",
              "Undocumented immigrants—Government policy—United States"
            ]
            corrected_subjects_atomic = [
              "Christianity",
              "Christianity and law",
              "Emigration and immigration",
              "Emigration and immigration law",
              "Government policy",
              "Political theology",
              "Religion and state",
              "Religious aspects",
              "Undocumented immigrants",
              "United States"
            ]
            replaced_terms = ["Illegal aliens—Government policy—United States", "Illegal aliens—United States"]
            subjects_for_searching = corrected_subjects_compound + replaced_terms

            expect(@change_the_subject1["subject_facet"]).to match_array(corrected_subjects_compound)
            expect(@change_the_subject1["subject_topic_facet"]).to match_array(corrected_subjects_atomic)
            expect(@change_the_subject1["lc_subject_display"]).to match_array(corrected_subjects_compound)
            expect(@change_the_subject1["subject_unstem_search"]).to match_array(subjects_for_searching)
          end
        end
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
      it "Indexes H - P, if a private SCSB record" do
        expect(@scsb_private["recap_notes_display"]).to eq ["H - P"]
      end
      it "Indexes C - S, if a shared SCSB record" do
        expect(@scsb_alt_title["recap_notes_display"]).to eq ["C - S"]
      end
      it "Indexes N - O, if not a private/shared SCSB record" do
        expect(@scsb_nypl["recap_notes_display"]).to eq ["N - O"]
      end
      it "Indexes H - C, if committed SCSB record" do
        expect(@scsb_committed["recap_notes_display"]).to eq ["H - C"]
      end
      it "Indexes H - U, if uncommittable SCSB record" do
        expect(@scsb_uncommittable["recap_notes_display"]).to eq ["H - U"]
      end
    end
  end
  context "invalid utf8 record" do
    it "ignores errors and allows the indexer to continue" do
      indexer = IndexerService.build
      sample = indexer.map_record(fixture_record('99125119454006421', indexer: indexer))
      expect(sample).to be_nil
    end
  end

  context "Temporary in resource sharing location" do
    it "does not show as a temporary location" do
      indexer = IndexerService.build
      sample = indexer.map_record(fixture_record('998370993506421', indexer: indexer))
      holdings = JSON.parse(sample['holdings_1display'][0])
      expect(holdings['22561746630006421']['items'].count).to eq 1
      expect(holdings['22561746630006421']["location"]).to eq "Remote Storage (ReCAP): Mendel Music Library Use Only"
      expect(sample["location"]).to eq(["Mendel Music Library"])
    end
  end
end
