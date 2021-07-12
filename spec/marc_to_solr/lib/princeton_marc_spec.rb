# encoding: UTF-8
require 'rails_helper'

describe 'From princeton_marc.rb' do
  before(:all) do
    @indexer = IndexerService.build
  end

  def fixture_record(fixture_name)
    f = File.expand_path("../../../fixtures/marc_to_solr/#{fixture_name}.mrx", __FILE__)
    @indexer.reader!(f).first
  end

  let(:indexer) { IndexerService.build }

  let(:ark) { "ark:/88435/xp68kg247" }
  let(:bib_id) { "9947151893506421" }
  let(:docs) do
    [
      {
        id: "b65cd851-ef01-45f2-b5bd-28c6616574ca",
        internal_resource_tsim: [
          "ScannedResource"
        ],
        internal_resource_ssim: [
          "ScannedResource"
        ],
        internal_resource_tesim: [
          "ScannedResource"
        ],
        identifier_tsim: [
          ark
        ],
        identifier_ssim: [
          ark
        ],
        identifier_tesim: [
          ark
        ],
        source_metadata_identifier_tsim: [
          bib_id
        ],
        source_metadata_identifier_ssim: [
          bib_id
        ],
        source_metadata_identifier_tesim: [
          bib_id
        ]

      }
    ]
  end
  let(:pages) do
    {
      "current_page": 1,
      "next_page": 2,
      "prev_page": nil,
      "total_pages": 1,
      "limit_value": 10,
      "offset_value": 0,
      "total_count": 1,
      "first_page?": true,
      "last_page?": true
    }
  end
  let(:results) do
    {
      "response": {
        "docs": docs,
        "facets": [],
        "pages": pages
      }
    }
  end

  before do
    stub_request(:get, "https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000").to_return(status: 200, body: JSON.generate(results))
  end

  describe '#electronic_access_links' do
    subject(:links) { electronic_access_links(marc_record, figgy_dir_path) }
    let(:figgy_dir_path) { ENV['FIGGY_ARK_CACHE_PATH'] || 'spec/fixtures/marc_to_solr/figgy_ark_cache' }

    let(:url) { 'https://domain.edu/test-resource' }
    let(:l001) { { '001' => '9947652213506421' } }
    let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url }] } } }
    let(:marc_record) { MARC::Record.new_from_hash('fields' => [l001, l856]) }
    let(:logger) { instance_double(Logger, info: nil, error: nil, debug: nil, warn: nil) }

    it 'retrieves the URLs and the link labels' do
      expect(links).to include('https://domain.edu/test-resource' => ['domain.edu'])
    end

    context 'without a URL' do
      let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [] } } }

      it 'retrieves no URLs' do
        expect(links).to be_empty
      end
    end

    context 'with a URL for an ARK' do
      let(:l856_2) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url, "z" => "label" }] } } }
      let(:l856_3) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url, "3" => "Selected images" }] } } }
      let(:url) { 'http://arks.princeton.edu/ark:/88435/00000140q' }
      let(:marc_record) { MARC::Record.new_from_hash('fields' => [l001, l856, l856_2, l856_3]) }

      it 'retrieves the URL for the current resource' do
        expect(links).to include('https://catalog.princeton.edu/catalog/4765221#view' => ['Digital content'])
        expect(links).to include('https://catalog.princeton.edu/catalog/4765221#view_1' => ['Digital content', 'label'])
        expect(links).to include('https://catalog.princeton.edu/catalog/4765221#view_2' => ['Selected images'])
        expect(links).not_to include('http://arks.princeton.edu/ark:/88435/00000140q' => ['arks.princeton.edu'])
      end

      context 'for a Figgy resource' do
        it 'generates the IIIF manifest path' do
          expect(links).to include('iiif_manifest_paths' => { 'http://arks.princeton.edu/ark:/88435/00000140q' => 'https://figgy.princeton.edu/concern/scanned_resources/181f7a9d-7e3c-4519-a79f-90113f65a14d/manifest' })
        end
      end
    end

    context 'with a holding ID in the 856$0 subfield' do
      let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url }, { "0" => "test-holding-id" }] } } }

      it 'retrieves the URLs and the link labels' do
        expect(links).to include('holding_record_856s' => { 'test-holding-id' => { 'https://domain.edu/test-resource' => ['domain.edu'] } })
      end
    end

    context 'with a label' do
      let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url }, { "z" => "test label" }] } } }

      it 'retrieves the URLs and the link labels' do
        expect(links).to include('https://domain.edu/test-resource' => ['domain.edu', 'test label'])
      end
    end

    context 'with link text in the 856$y subfield' do
      let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url }, { "y" => "test text1" }] } } }

      it 'retrieves the URLs and the link labels' do
        expect(links).to include('https://domain.edu/test-resource' => ['test text1'])
      end
    end

    context 'with link text in the 856$3 subfield' do
      let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url }, { "3" => "test text2" }] } } }

      it 'retrieves the URLs and the link labels' do
        expect(links).to include('https://domain.edu/test-resource' => ['test text2'])
      end
    end

    context 'with link text in the 856$x subfield' do
      let(:l856) { { "856" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "u" => url }, { "x" => "test text3" }] } } }

      it 'skips subfield $x' do
        expect(links).not_to include('https://domain.edu/test-resource' => ['test text3'])
      end
    end

    context 'with an invalid URL' do
      let(:url) { 'some_invalid_value' }

      it 'retrieves no URLs' do
        expect(links).to be_empty
      end

      it 'logs an error' do
        ElectronicAccessLink.new(bib_id: 9_947_652_213_506_421, holding_id: nil, z_label: nil, anchor_text: nil, url_key: url, logger: logger)
        expect(logger).to have_received(:error).with("9947652213506421 - invalid URL for 856$u value: #{url}")
      end
    end

    context 'with an invalid URL which still manages to be match the valid uri regexp' do
      let(:url) { 'http://www.strategicstudiesinstitute.army.mil/pdffiles/PUB949[1].pdf' }

      it 'logs an error' do
        ElectronicAccessLink.new(bib_id: 9_947_652_213_506_421, holding_id: nil, z_label: nil, anchor_text: nil, url_key: url, logger: logger)
        expect(logger).to have_received(:error).with("9947652213506421 - invalid URL for 856$u value: #{url}")
      end
    end

    context 'with an unparsable URL' do
      let(:url) do
        a = "\xFF"
        a.force_encoding "utf-8"
      end

      it 'retrieves no URLs' do
        expect(links).to be_empty
      end

      it 'logs an error' do
        ElectronicAccessLink.new(bib_id: 9_947_652_213_506_421, holding_id: nil, z_label: nil, anchor_text: nil, url_key: url, logger: logger)
        expect(logger).to have_received(:error).with("9947652213506421 - invalid character encoding for 856$u value: #{url}")
      end
    end

    context 'with a URL with the "|" encoded as a query parameter' do
      let(:url) { 'http://go.galegroup.com/ps/i.do?id=GALE%7C9781440840869&v=2.1&u=prin77918&it=etoc&p=GVRL&sw=w' }
      it 'ensures that escaped characters are escaped only once' do
        expect(links).to include('http://go.galegroup.com/ps/i.do?id=GALE%7C9781440840869&v=2.1&u=prin77918&it=etoc&p=GVRL&sw=w' => ['go.galegroup.com'])
      end
    end

    context 'with a URL not properly escaped' do
      let(:url) { 'http://www.archivesdirect.amdigital.co.uk/Documents/Details/FO 424_144' }
      it 'ensures all characters are escaped that should be escaped' do
        expect(links).to include('http://www.archivesdirect.amdigital.co.uk/Documents/Details/FO%20424_144' => ['www.archivesdirect.amdigital.co.uk'])
      end
    end
    context 'with a URL fragment' do
      let(:url) { 'http://libweb5.princeton.edu/visual_materials/maps/globes-objects/hmc05.html#stella' }
      it 'preserves fragment' do
        expect(links).to include('http://libweb5.princeton.edu/visual_materials/maps/globes-objects/hmc05.html#stella' => ['libweb5.princeton.edu'])
      end
    end
  end

  describe 'standard_no_hash with keys based on the first indicator' do
    before(:all) do
      @key_for_3 = "International Article Number"
      @key_for_4 = "Serial Item and Contribution Identifier"
      @default_key = "Other standard number"
      @sub2_key = "Special number"
      @ind1_3 = { "024" => { "ind1" => "3", "ind2" => " ", "subfields" => [{ "a" => '111' }] } }
      @ind1_4 = { "024" => { "ind1" => "4", "ind2" => " ", "subfields" => [{ "a" => '123' }] } }
      @ind1_4_second = { "024" => { "ind1" => "4", "ind2" => " ", "subfields" => [{ "a" => '456' }] } }
      @ind1_8 = { "024" => { "ind1" => "8", "ind2" => " ", "subfields" => [{ "a" => '654' }] } }
      @ind1_blank = { "024" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => '321' }] } }
      @ind1_7 = { "024" => { "ind1" => "7", "ind2" => " ", "subfields" => [{ "a" => '789' }, "2" => @sub2_key] } }
      @missing_sub2 = { "024" => { "ind1" => "7", "ind2" => " ", "subfields" => [{ "a" => '987' }] } }
      @empty_sub2 = { "024" => { "ind1" => "7", "ind2" => " ", "subfields" => [{ "a" => '000', "2" => '' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@ind1_3, @ind1_4, @ind1_4_second, @ind1_8, @ind1_blank, @ind1_7, @missing_sub2, @empty_sub2])
      @standard_nos = standard_no_hash(@sample_marc)
    end

    it 'includes standard no as value associated with indicator type' do
      expect(@standard_nos[@key_for_3]).to include(@ind1_3['024']['subfields'][0]['a'])
    end

    it 'supports multiple values for each key' do
      expect(@standard_nos[@key_for_4]).to include(@ind1_4['024']['subfields'][0]['a'])
      expect(@standard_nos[@key_for_4]).to include(@ind1_4_second['024']['subfields'][0]['a'])
    end

    it 'takes key value from subfield 2 when indicator 1 is 7' do
      expect(@standard_nos[@sub2_key]).to include(@ind1_7['024']['subfields'][0]['a'])
    end

    it '024 fields that without 0,1,2,3,4, or 7 in indicator 1 have a default key' do
      expect(@standard_nos[@default_key]).to include(@ind1_8['024']['subfields'][0]['a'])
      expect(@standard_nos[@default_key]).to include(@ind1_blank['024']['subfields'][0]['a'])
    end

    it '024 fields with 7 in indicator 1 but blank or nil subfield 2 use the default key' do
      expect(@standard_nos[@default_key]).to include(@empty_sub2['024']['subfields'][0]['a'])
      expect(@standard_nos[@default_key]).to include(@missing_sub2['024']['subfields'][0]['a'])
    end
  end

  describe 'oclc_s normalize' do
    it 'without prefix' do
      expect(oclc_normalize("(OCoLC)882089266")).to eq("882089266")
      expect(oclc_normalize("(OCoLC)on9990014350")).to eq("9990014350")
      expect(oclc_normalize("(OCoLC)ocn899745778")).to eq("899745778")
      expect(oclc_normalize("(OCoLC)ocm00012345")).to eq("12345")
    end

    it 'with prefix' do
      expect(oclc_normalize("(OCoLC)882089266", prefix: true)).to eq("ocn882089266")
      expect(oclc_normalize("(OCoLC)on9990014350", prefix: true)).to eq("on9990014350")
      expect(oclc_normalize("(OCoLC)ocn899745778", prefix: true)).to eq("ocn899745778")
      expect(oclc_normalize("(OCoLC)ocm00012345", prefix: true)).to eq("ocm00012345")
    end

    it "source with and without prefix normalize the same way" do
      expect(oclc_normalize("(OCoLC)ocm00012345")).to eq(oclc_normalize("(OCoLC)12345"))
      expect(oclc_normalize("(OCoLC)ocm00012345", prefix: true)).to eq(oclc_normalize("(OCoLC)12345", prefix: true))
    end
  end

  describe 'other_versions function' do
    before(:all) do
      @bib = '9947652213506421'
      @bib_776w = { "776" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "w" => @bib }] } }
      @non_oclc_non_bib = '(DLC)12345678'
      @non_oclc_non_bib_776w = { "776" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "w" => @non_oclc_non_bib }] } }
      @oclc_num = '(OCoLC)on9990014350'
      @oclc_776w = { "776" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "w" => @oclc_num }] } }
      @oclc_num2 = '(OCoLC)on9990014351'
      @oclc_num3 = '(OCoLC)on9990014352'
      @oclc_787w = { "787" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "w" => @oclc_num2 }, { "z" => @oclc_num3 }] } }
      @oclc_num4 = '(OCoLC)on9990014353'
      @oclc_035a = { "035" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => @oclc_num4 }] } }
      @issn_num = "0378-5955"
      @issn_022 = { "022" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "l" => @issn_num }, { "y" => @issn_num }] } }
      @issn_num2 = "1234-5679"
      @issn_776x = { "776" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "x" => @issn_num2 }] } }
      @isbn_num = '0-9752298-0-X'
      @isbn_776z = { "776" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "z" => @isbn_num }] } }
      @isbn_num2 = 'ISBN: 978-0-306-40615-7'
      @isbn_num2_10d = '0-306-40615-2'
      @isbn_020 = { "020" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => @isbn_num2 }, { "z" => @isbn_num2_10d }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@bib_776w, @non_oclc_non_bib_776w, @oclc_776w, @oclc_787w, @oclc_035a, @issn_022, @issn_776x, @isbn_776z, @isbn_020])
      @linked_nums = other_versions(@sample_marc)
    end

    it 'includes isbn, issn, oclc nums for expected fields/subfields' do
      expect(@linked_nums).to include(oclc_normalize(@oclc_num, prefix: true))
      expect(@linked_nums).to include(oclc_normalize(@oclc_num2, prefix: true))
      expect(@linked_nums).to include(oclc_normalize(@oclc_num4, prefix: true))
      expect(@linked_nums).to include('BIB' + strip_non_numeric(@bib))
      expect(@linked_nums).to include(StdNum::ISSN.normalize(@issn_num))
      expect(@linked_nums).to include(StdNum::ISSN.normalize(@issn_num2))
      expect(@linked_nums).to include(StdNum::ISBN.normalize(@isbn_num))
      expect(@linked_nums).to include(StdNum::ISBN.normalize(@isbn_num2))
      expect(@linked_nums).to include(StdNum::ISBN.normalize(@isbn_num2_10d))
    end

    it 'removes duplicates' do
      expect(StdNum::ISBN.normalize(@isbn_num2)).to eq(StdNum::ISBN.normalize(@isbn_num2_10d))
      expect(@linked_nums.count(StdNum::ISSN.normalize(@issn_num))).to eq 1
      expect(@linked_nums.count(StdNum::ISBN.normalize(@isbn_num2_10d))).to eq 1
    end

    it 'excludes numbers not in expect subfields' do
      expect(@linked_nums).not_to include(oclc_normalize(@oclc_num3, prefix: true))
    end

    it 'excludes non oclc/non bib in expected oclc/bib subfield' do
      expect(@linked_nums).not_to include(oclc_normalize(@non_oclc_non_bib, prefix: true))
    end
  end

  describe 'process_names, process_alt_script_names function' do
    before(:all) do
      @t100 = { "100" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "John" }, { "d" => "1492" }, { "t" => "TITLE" }, { "k" => "ignore" }] } }
      @t700 = { "700" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "John" }, { "d" => "1492" }, { "k" => "don't ignore" }, { "t" => "TITLE" }] } }
      @t880 = { "880" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "100-1" }, { "a" => "Κινέζικα" }, { "t" => "TITLE" }, { "k" => "ignore" }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@t100, @t700, @t880])
    end

    it 'strips subfields that appear after subfield $t, includes 880' do
      names = process_names(@sample_marc)
      expect(names).to include("John 1492")
      expect(names).to include("John 1492 don't ignore")
      expect(names).not_to include("John 1492 ignore")
      expect(names).to include("Κινέζικα")
    end
    it 'alt_script version only includes the 880' do
      names = process_alt_script_names(@sample_marc)
      expect(names).to include("Κινέζικα")
      expect(names).not_to include("John 1492")
    end
  end

  describe '#everything_after_t, #everything_after_t_alt_script' do
    before(:all) do
      t100 = { "100" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "IGNORE" }, { "d" => "me" }, { "t" => "TITLE" }] } }
      t710 = { "710" => { "ind1" => "1", "ind2" => "2", "subfields" => [{ "t" => "AWESOME" }, { "a" => "John" }, { "d" => "1492" }, { "k" => "dont ignore" }] } }
      t880 = { "880" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "6" => "100-1" }, { "a" => "IGNORE" }, { "d" => "me" }, { "t" => "Τίτλος" }] } }
      ignore700 = { "700" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "t" => "should not include" }, { "a" => "when missing indicators" }] } }
      no_t = { "700" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "please" }, { "d" => "disregard" }, { "k" => "no title" }] } }
      sample_marc = MARC::Record.new_from_hash('fields' => [t100, t710, no_t, t880])
      @titles = everything_after_t(sample_marc, '100:700:710')
      @alt_titles = everything_after_t_alt_script(sample_marc, '100:700:710')
      indicators_marc = MARC::Record.new_from_hash('fields' => [ignore700, t710])
      @indicator_titles = everything_after_t(indicators_marc, '700|12|:710|12|:711|12|')
    end
    it 'includes subfield $t when last subfield' do
      expect(@titles).to include('TITLE')
    end
    it 'inlcudes subfield $t and subfields after $t' do
      expect(@titles).to include('AWESOME John 1492 dont ignore')
    end
    it 'titles includes 880 field' do
      expect(@titles).to include('Τίτλος')
    end
    it 'excludes fields with no subfield $t' do
      expect(@titles).not_to include('please disregard no title')
    end
    it 'expects indicator matcher to factor into matching lines' do
      expect(@indicator_titles).to match_array(['AWESOME John 1492 dont ignore'])
    end
    it 'alt_titles includes 880 field' do
      expect(@alt_titles).to include('Τίτλος')
    end
    it 'alt_titles excludes 100 field' do
      expect(@alt_titles).not_to include('TITLE')
    end
  end

  describe '#everything_through_t' do
    before(:all) do
      t100 = { "100" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "d" => "me" }, { "t" => "TITLE" }, { "a" => "IGNORE" }] } }
      t710 = { "710" => { "ind1" => "1", "ind2" => "2", "subfields" => [{ "t" => "AWESOME" }, { "a" => "John" }, { "d" => "1492" }, { "k" => "ignore" }] } }
      no_t = { "700" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "please" }, { "d" => "disregard" }, { "k" => "no title" }] } }
      sample_marc = MARC::Record.new_from_hash('fields' => [t100, t710, no_t])
      @titles = everything_through_t(sample_marc, '100:700:710')
    end

    it 'includes subfield $t when first subfield' do
      expect(@titles).to include('AWESOME')
    end
    it 'inlcudes subfield $t and subfields before $t' do
      expect(@titles).to include('me TITLE')
    end
    it 'excludes fields with no subfield $t' do
      expect(@titles).not_to include('please disregard no title')
    end
  end

  describe '#prep_name_title, each hierarchical component is array element' do
    before(:all) do
      t700 = { "700" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "John" }, { "d" => "1492" }, { "t" => "TITLE" }, { "0" => "(uri)" }] } }
      no_title_700 = { "700" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "a" => "Mike" }, { "p" => "part" }] } }
      no_author_710 = { "710" => { "ind1" => "", "ind2" => " ", "subfields" => [{ "d" => "1500" }, { "t" => "Title" }, { "p" => "part" }] } }
      t710 = { "710" => { "ind1" => "", "ind2" => "2", "subfields" => [{ "a" => "Sean" }, { "d" => "2011" }, { "t" => "work" }, { "n" => "53" }, { "p" => "Allegro" }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [t700, no_title_700, no_author_710, t710])
    end

    it '$t required, includes only specified subfields' do
      name_titles_700 = prep_name_title(@sample_marc, '700adt')
      expect(name_titles_700[0]).to match_array(['John 1492', 'TITLE'])
    end

    it '$a required, split happens before $t' do
      name_titles_710 = prep_name_title(@sample_marc, '710')
      expect(name_titles_710[0]).to match_array(['Sean 2011', 'work', '53', 'Allegro'])
    end

    it '#join_hierarchy combines hierarchical component with parent components' do
      name_titles = join_hierarchy(prep_name_title(@sample_marc, '700adt:710'))
      expect(name_titles).to match_array([['John 1492 TITLE'], ['Sean 2011 work', 'Sean 2011 work 53', 'Sean 2011 work 53 Allegro']])
    end
  end

  describe 'process_genre_facet function' do
    before(:all) do
      @g600 = { "600" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "Exclude" }, { "v" => "John" }, { "x" => "Join" }] } }
      @g630 = { "630" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "x" => "Fiction." }] } }
      @g655 = { "655" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "Culture." }, { "x" => "Dramatic rendition" }, { "v" => "Awesome" }] } }
      @g655_2 = { "655" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Poetry" }, { "x" => "Translations into French" }, { "v" => "Maps" }] } }
      @g655_3 = { "655" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Manuscript" }, { "x" => "Translations into French" }, { "v" => "Genre" }, { "2" => "rbgenr" }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@g600, @g630, @g655, @g655_2, @g655_3])
      @genres = process_genre_facet(@sample_marc)
    end

    it 'trims punctuation' do
      expect(@genres).to include("Culture")
    end

    it 'excludes $a when not 655' do
      expect(@genres).not_to include("Exclude")
    end

    it 'excludes 2nd indicator of 7 if vocab type is not in approved list' do
      expect(@genres).not_to include("Maps")
      expect(@genres).not_to include("Poetry")
    end

    it 'includes 2nd indicator of 7 if vocab type is in approved list' do
      expect(@genres).to include("Manuscript")
      expect(@genres).to include("Genre")
    end

    it 'includes 6xx $v and 655 $a' do
      expect(@genres).to include("John")
      expect(@genres).to include("Awesome")
    end

    it 'includes 6xx $x from filtered in terms' do
      expect(@genres).to include("Fiction")
    end

    it 'excludes $x terms that do not match filter list' do
      expect(@genres).not_to include("Join")
      expect(@genres).not_to include("Dramatic renditon")
    end
  end

  describe 'process_hierarchy function' do
    before(:all) do
      @s610_ind2_5 = { "600" => { "ind1" => "", "ind2" => "5", "subfields" => [{ "a" => "Exclude" }] } }
      @s600_ind2_7 = { "600" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Also Exclude" }] } }
      @s600 = { "600" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "John." }, { "t" => "Title." }, { "v" => "split genre" }, { "d" => "2015" }, { "2" => "special" }] } }
      @s630 = { "630" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "x" => "Fiction" }, { "y" => "1492" }, { "z" => "don't ignore" }, { "t" => "TITLE." }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@s610_ind2_5, @s600, @s630])
      @subjects = process_hierarchy(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz')
      @vocab_subjects = process_hierarchy(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz', ['vocab'])
      @special_subjects = process_hierarchy(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz', ['special'])
    end

    describe 'when an optional vocabulary limit is not provided' do
      it 'excludes subjects without 0 in the 2nd indicator' do
        expect(@subjects).not_to include("Exclude")
        expect(@subjects).not_to include("Also Exclude")
      end

      it 'only separates t,v,x,y,z with em dash, strips punctuation' do
        expect(@subjects).to include("John#{SEPARATOR}Title#{SEPARATOR}split genre 2015")
        expect(@subjects).to include("Fiction#{SEPARATOR}1492#{SEPARATOR}don't ignore#{SEPARATOR}TITLE")
      end
    end

    describe 'when a vocabulary limit is provided' do
      it 'excludes headings missing a subfield 2 or part of a different vocab' do
        expect(@vocab_subjects).to eq []
      end
      it 'only includes the heading from a matching subfield 2 value' do
        expect(@special_subjects).to eq ["John#{SEPARATOR}Title#{SEPARATOR}split genre 2015"]
      end
    end
  end

  describe 'process_subject_topic_facet function' do
    before(:all) do
      @s600 = { "600" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "a" => "John." }, { "x" => "Join" }, { "t" => "Title" }, { "d" => "2015" }] } }
      @s630 = { "630" => { "ind1" => "", "ind2" => "0", "subfields" => [{ "x" => "Fiction" }, { "y" => "1492" }, { "z" => "don't ignore" }, { "v" => "split genre" }, { "t" => "TITLE" }] } }
      @s650_sk = { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Siku subject" }, { "x" => "Siku hierarchy" }, { "2" => "sk" }] } }
      @s650_exclude = { "650" => { "ind1" => "", "ind2" => "7", "subfields" => [{ "a" => "Bad subject" }, { "2" => "bad" }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@s600, @s630, @s650_sk])
      @subjects = process_subject_topic_facet(@sample_marc)
    end

    it 'trims punctuation' do
      expect(@subjects).to include("John")
    end

    it 'excludes v and y' do
      expect(@subjects).not_to include("1492")
      expect(@subjects).not_to include("split genre")
    end

    it 'excludes non-approved subfield $2 vocab types' do
      expect(@subjects).not_to include("Bad subject")
    end

    it 'includes subjects split along x or z' do
      expect(@subjects).to include("Join Title 2015")
      expect(@subjects).to include("Fiction")
      expect(@subjects).to include("don't ignore TITLE")
    end
  end

  describe 'process_author_roles' do
    before(:all) do
      @aut1 = "Lahiri, Jhumpa"
      @aut2 = "Eugenides, Jeffrey"
      @aut3 = "Cole, Teju"
      @aut4 = "Nikolakopoulou, Evangelia"
      @aut5 = "Morrison, Toni"
      @aut6 = "Oates, Joyce Carol"
      @aut7 = "Marchesi, Simone"
      @aut8 = "Fitzgerald, F. Scott"

      @a100 = { "100" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut1 }] } }
      @a700_1 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut2 }, { "4" => 'edt' }] } }
      @a700_2 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut3 }, { "4" => 'com' }] } }
      @a700_3 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut4 }, { "4" => 'trl' }] } }
      @a700_4 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut5 }, { "4" => 'aaa' }] } }
      @a700_5 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut6 }] } }
      @a700_6 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut7 }, { "e" => 'translator.' }] } }
      @a700_7 = { "700" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @aut8 }, { "e" => 'ed.' }] } }

      @sample_marc = MARC::Record
                     .new_from_hash('fields' => [@a100, @a700_1, @a700_2,
                                                 @a700_3, @a700_4, @a700_5,
                                                 @a700_6, @a700_7])
      @roles = process_author_roles(@sample_marc)
    end

    it 'list 1xx as primary author' do
      expect(@roles['primary_author']).to eq @aut1
    end
    it '7xx authors with edt subfield 4 code are editors' do
      expect(@roles['editors']).to include @aut2
    end
    it '7xx authors with com subfield 4 code are compilers' do
      expect(@roles['compilers']).to include @aut3
    end
    it '7xx authors with trl subfield 4 code are translators' do
      expect(@roles['translators']).to include @aut4
    end
    it '7xx authors without matched roles are secondary authors' do
      expect(@roles['secondary_authors']).to include @aut5
      expect(@roles['secondary_authors']).to include @aut6
    end
    it '7xx authors with translator subfield e term are translators' do
      expect(@roles['translators']).to include @aut7
    end
    it '7xx authors with unmatched subfield e term are secondary_authors' do
      expect(@roles['secondary_authors']).to include @aut8
    end
  end

  describe 'set_pub_citation' do
    before(:all) do
      @place1 = 'Princeton'
      @name1 = 'Princeton University Press'
      @place2 = 'Brooklyn'
      @name2 = 'Archipelago Books'

      @p260_a = { "260" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @place1 }] } }
      @p260_b = { "260" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "b" => @name1 }] } }
      @p260_a_b = { "260" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @place1 }, { "b" => @name1 }] } }
      @p264_a = { "264" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @place2 }] } }
      @p264_b = { "264" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "b" => @name2 }] } }
      @p264_a_b = { "264" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "a" => @place2 }, { "b" => @name2 }] } }

      @sample_marc_a = MARC::Record.new_from_hash('fields' => [@p260_a, @p264_a])
      @sample_marc_b = MARC::Record.new_from_hash('fields' => [@p260_b, @p264_b])
      @sample_marc_a_b = MARC::Record.new_from_hash('fields' => [@p260_a_b, @p264_a_b])

      @citation_a = set_pub_citation(@sample_marc_a)
      @citation_b = set_pub_citation(@sample_marc_b)
      @citation_a_b = set_pub_citation(@sample_marc_a_b)
    end

    it 'record with fields 260 or 264 and only subfield a will have a place-only citation' do
      expect(@citation_a).to include @place1
      expect(@citation_a).to include @place2
    end
    it 'record with fields 260 or 264 and only subfield b will have a name-only citation' do
      expect(@citation_b).to include @name1
      expect(@citation_b).to include @name2
    end
    it 'record with fields 260 or 264 with subfield a and b will have a concatenated citation' do
      expect(@citation_a_b).to include "#{@place1}: #{@name1}"
      expect(@citation_a_b).to include "#{@place2}: #{@name2}"
    end
  end

  describe '#process_holdings' do
    # voyager record: https://catalog.princeton.edu/catalog/1414145/
    # alma record: https://bibdata-alma-staging.princeton.edu/bibliographic/9914141453506421
    before(:all) do
      @record_no_location_name = @indexer.map_record(fixture_record('99116547863506421'))
      @holdings_no_location_name = JSON.parse(@record_no_location_name["holdings_1display"][0])
      @holdings_no_location_name_holding_block = @holdings_no_location_name["22211952510006421"]

      @record = @indexer.map_record(fixture_record('9914141453506421'))
      @holdings = JSON.parse(@record["holdings_1display"][0])
      @oversize_holding_id = "22242008800006421"
      @oversize_holding_block = @holdings[@oversize_holding_id]

      @record_no_876t = @indexer.map_record(fixture_record('9914141453506421_custom_no_876t'))
      @holdings_no_876 = JSON.parse(@record["holdings_1display"][0])
      @holding_id_no_876t = "22242008800006421"
      @holding_block_no_876t = @holdings_no_876[@holding_id_no_876t]

      @record_866_867 = @indexer.map_record(fixture_record('991583506421'))
      @holdings_866_867 = JSON.parse(@record_866_867["holdings_1display"][0])
      @holding_id_866_867 = "22262098640006421"
      @holdings_866_867_block = @holdings_866_867[@holding_id_866_867]

      @record_868 = @indexer.map_record(fixture_record('991213506421'))
      @holdings_868 = JSON.parse(@record_868["holdings_1display"][0])
      @holding_id_868 = "22261907460006421"
      @holdings_868_block = @holdings_868[@holding_id_868]

      @record_invalid_location = @indexer.map_record(fixture_record('9914141453506421_invalid_loc'))
      @not_valid_holding_id = "999999"
      @holdings_id_852 = "22242008800006421"
      @holdings_with_invalid_location = JSON.parse(@record_invalid_location["holdings_1display"][0])

      # scsb
      @record_scsb = @indexer.map_record(fixture_record('SCSB-8157262'))
      @holdings_scsb = JSON.parse(@record_scsb["holdings_1display"][0])
      @holding_id_scsb = "9856684"
      @holdings_scsb_block = @holdings_scsb[@holding_id_scsb]
    end

    it 'indexes location if it exists' do
      expect(@oversize_holding_block['location']).to eq 'Stacks'
    end

    it 'if location is blank it will index blank' do
      expect(@holdings_no_location_name_holding_block["location"]).to eq ''
    end

    it 'includes only first location code' do
      expect(@oversize_holding_block['location_code']).to eq("annex$stacks")
    end

    it 'excludes holdings with an invalid location code' do
      expect(@holdings_with_invalid_location).not_to have_key(@not_valid_holding_id)
      expect(@holdings_with_invalid_location).to have_key(@holdings_id_852)
    end

    it 'positions $k at the end for call_number_browse field' do
      expect(@oversize_holding_block['call_number_browse']).to include('Oversize')
      expect(@oversize_holding_block['call_number_browse']).to eq("M23.L5S6 1973q Oversize")
    end

    describe 'copy_number is included in the items' do
      it "includes copy_number from first instance of 876 $t" do
        expect(@oversize_holding_block["items"].first["copy_number"]).to eq('10')
      end

      it 'only includes copy_number if there is an 876 $t' do
        expect(@holding_block_no_876t['copy_number']).to be_nil
      end
    end

    it 'separates call_number subfields with whitespace' do
      expect(@oversize_holding_block['call_number']).to eq("M23.L5S6 1973q Oversize")
    end

    it 'location_has takes from 866 $a and $z regardless of indicators' do
      expect(@holdings_866_867_block['location_has']).to include("No. 1 (Feb. 1975)-no. 68", "LACKS: no. 25-26,29,49-50, 56")
    end
    it 'supplements takes from 867 $a and $z' do
      expect(@holdings_866_867_block['supplements']).to include("no. 20")
    end
    it 'indexes takes from 868 $a and $z' do
      expect(@holdings_868_block['indexes']).to include("Index, v. 1/17")
    end

    describe "scsb process holdings" do
      it "indexes from 852" do
        expect(@holdings_scsb).to have_key(@holding_id_scsb)
        expect(@holdings_scsb_block['location_code']).to eq('scsbnypl')
        expect(@holdings_scsb_block['location']).to eq('ReCAP')
        expect(@holdings_scsb_block['library']).to eq('ReCAP')
        expect(@holdings_scsb_block['call_number_browse']).to eq('JSM 95-216')
        expect(@holdings_scsb_block['call_number']).to eq('JSM 95-216')
      end
      it "indexes location_has from 866" do
        expect(@holdings_scsb_block['location_has']).to eq(["no. 107-112"])
      end
      it "indexes 876 for scsb" do
        expect(@holdings_scsb_block['items'][0]['enumeration']).to eq("no. 107-112")
        expect(@holdings_scsb_block['items'][0]['id']).to eq("15555520")
        expect(@holdings_scsb_block['items'][0]['use_statement']).to eq("In Library Use")
        expect(@holdings_scsb_block['items'][0]['status_at_load']).to eq("Available")
        expect(@holdings_scsb_block['items'][0]['barcode']).to eq("33433022784528")
        expect(@holdings_scsb_block['items'][0]['copy_number']).to eq("1")
        expect(@holdings_scsb_block['items'][0]['cgc']).to eq("Open")
        expect(@holdings_scsb_block['items'][0]['collection_code']).to eq("JS")
      end
    end
  end
end
