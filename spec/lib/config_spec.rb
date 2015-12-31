require 'json'
require 'traject'
require 'faraday'

describe 'From traject_config.rb' do
  before(:all) do

    def fixture_record(fixture_name)
      f=File.expand_path("../../fixtures/#{fixture_name}.mrx",__FILE__)
      MARC::XMLReader.new(f).first
    end
    c=File.expand_path('../../../lib/traject_config.rb',__FILE__)
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
    @sample1=@indexer.map_record(fixture_record('sample1'))
    @sample2=@indexer.map_record(fixture_record('sample2'))
    @sample3=@indexer.map_record(fixture_record('sample3'))
    @added_title_246=@indexer.map_record(fixture_record('sample18'))
    @related_names=@indexer.map_record(fixture_record('sample27'))
    @label_i_246=@indexer.map_record(fixture_record('sample28'))
    @online_at_library=@indexer.map_record(fixture_record('sample29'))
    @online=@indexer.map_record(fixture_record('sample30'))
    @other_title_246=@indexer.map_record(fixture_record('7910599'))
    config = YAML.load(ERB.new(File.read('config/solr.yml')).result)
    @conn = Faraday.new(:url => config['marc_liberation']) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
	end

  describe 'the id field' do
    it 'has exactly 1 value' do
      expect(@sample1['id'].length).to eq 1
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
  describe 'the pub_citation_display field' do
    it 'shows the the 260 a and b subfields' do
      expect(@sample2['pub_citation_display']).to include 'London: Firethorn Press'
    end
  end
  describe 'related_name_json_1display' do
    it 'trims punctuation the same way as author_s facet' do
      rel_names = JSON.parse(@related_names['related_name_json_1display'][0])
      rel_names['Related name'].each {|n| expect(@related_names['author_s']).to include(n)}
    end
  end
  describe 'access_facet' do
    it 'value is in the library for all non-online holding locations' do
      expect(@sample3['location_code_s'][0]).to eq 'scidoc' # Lewis Library
      expect(@sample3['access_facet']).to include 'In the Library'
      expect(@sample3['access_facet']).not_to include 'Online'
    end
    it 'value is online for elf holding locations' do
      expect(@online['location_code_s'][0]).to eq 'elf1'
      expect(@online['access_facet']).to include 'Online'
      expect(@online['access_facet']).not_to include 'In the Library'
    end
    it 'value can be both in the library and online when there are multiple holdings' do
      expect(@online_at_library['location_code_s']).to include 'elf1'
      expect(@online_at_library['location_code_s']).to include 'rcpph'
      expect(@online_at_library['access_facet']).to include 'Online'
      expect(@online_at_library['access_facet']).to include 'In the Library'
    end
  end
  describe 'holdings_1display' do
    before(:all) do
      resp = @conn.get "/bibliographic/7617477"
      marcxml = MARC::XMLReader.new(StringIO.new(resp.body)).first
      @solr_hash = @indexer.map_record(marcxml)
      @holding_block = JSON.parse(@solr_hash['holdings_1display'].first)
      resp = @conn.get "/bibliographic/7617477/holdings.json"
      holdings = JSON.parse(resp.body)
      @holding_records = []
      holdings.each {|h| @holding_records << MARC::Record.new_from_hash(h) }
    end
    it 'groups holding info into a hash keyed on the mfhd id' do
      @holding_records.each do |holding|
        holding_id = holding['001'].value
        expect(@holding_block[holding_id]['location_code']).to eq(holding['852']['b'])
        expect(@holding_block[holding_id]['location_note']).to eq(holding['852']['z'])
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
      expect(@online['location_code_s']).to include 'elf1'
      expect(@online['location']).to be_nil
    end

    it 'when location codes that do not map to labels' do
      expect(@sample1['location_code_s']).to include 'invalidcode'
      expect(@sample1['location']).to be_nil
    end
  end
  describe 'other_title_display array 246s included' do
    it 'when 2nd indicator is 3' do
      expect(@added_title_246['other_title_display']).to include 'Bi ni itaru yamai'
    end
    it 'when no indicator or $i' do
      expect(@other_title_246['other_title_display']).to include 'Episcopus, civitas, territorium'
    end
  end
  describe 'other_title_1display 246s hash' do
    it 'supports multiple titles per label' do
      other_title_hash = JSON.parse(@added_title_246['other_title_1display'].first)
      expect(other_title_hash['Added title page title']).to include 'Morimura Yasumasa, the sickness unto beauty'
      expect(other_title_hash['Added title page title']).to include 'Sickness unto beauty'
    end
    it 'uses label from $i when available' do
      other_title_hash = JSON.parse(@label_i_246['other_title_1display'].first)
      expect(other_title_hash['English title also known as']).to include 'Dad for rent'
    end
  end
end
