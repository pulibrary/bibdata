require 'json'
require 'traject'
require 'faraday'

describe 'From traject_config.rb' do
  def fixture_record(fixture_name)
    f=File.expand_path("../../fixtures/#{fixture_name}.mrx",__FILE__)
    MARC::XMLReader.new(f).first
  end

  before(:all) do
    c=File.expand_path('../../../lib/traject_config.rb',__FILE__)
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
    @sample1=@indexer.map_record(fixture_record('sample1'))
    @sample2=@indexer.map_record(fixture_record('sample2'))
    @sample3=@indexer.map_record(fixture_record('sample3'))
    @manuscript_book=@indexer.map_record(fixture_record('sample17'))
    @added_title_246=@indexer.map_record(fixture_record('sample18'))
    @related_names=@indexer.map_record(fixture_record('sample27'))
    @label_i_246=@indexer.map_record(fixture_record('sample28'))
    @online_at_library=@indexer.map_record(fixture_record('sample29'))
    @online=@indexer.map_record(fixture_record('sample30'))
    @elf2=@indexer.map_record(fixture_record('elf2'))
    @other_title_246=@indexer.map_record(fixture_record('7910599'))
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
    let(:rel_names) { JSON.parse(@related_names['related_name_json_1display'][0]) }
    it 'trims punctuation the same way as author_s facet' do
      rel_names['Related name'].each {|n| expect(@related_names['author_s']).to include(n)}
    end
    it 'allows multiple roles from single field' do
      expect(rel_names['Editor']).to include('Someone')
      expect(rel_names['Painter']).to include('Someone')
    end
  end
  describe 'access_facet' do
    it 'value is in the library for all non-online holding locations' do
      expect(@sample3['location_code_s'][0]).to eq 'scidoc' # Lewis Library
      expect(@sample3['access_facet']).to include 'In the Library'
      expect(@sample3['access_facet']).not_to include 'Online'
    end
    it 'value is at the library for elf2 holding location' do
      expect(@elf2['location_code_s'][0]).to eq 'elf2'
      expect(@elf2['access_facet']).not_to include 'Online'
      expect(@elf2['access_facet']).to include 'In the Library'
    end
    it 'value is online for all other elf holding locations' do
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
      marcxml = fixture_record('7617477')
      @solr_hash = @indexer.map_record(marcxml)
      @holding_block = JSON.parse(@solr_hash['holdings_1display'].first)
      holdings_file=File.expand_path("../../fixtures/7617477-holdings.json",__FILE__)
      holdings = JSON.parse(File.read(holdings_file))
      @holding_records = []
      holdings.each {|h| @holding_records << MARC::Record.new_from_hash(h) }
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
      expect(@online['location_code_s']).to include 'elf1'
      expect(@online['location_display']).to include 'Online - *ONLINE*'
      expect(@online['location']).to be_nil
    end

    it 'when location codes that do not map to labels' do
      expect(@sample1['location_code_s']).to include 'invalidcode'
      expect(@sample1['location_display']).to be_nil
      expect(@sample1['location']).to be_nil
    end
  end
  describe 'including libraries and codes in advanced_location_s facet' do
    it 'lewis library included with lewis code' do
      expect(@sample3['advanced_location_s']).to include 'scidoc'
      expect(@sample3['advanced_location_s']).to include 'Lewis Library'
    end
    it 'online is included' do
      expect(@elf2['advanced_location_s']).to include 'elf2'
      expect(@elf2['advanced_location_s']).to include 'Online'
    end
    it 'library is excluded from location_code_s' do
      expect(@sample3['location_code_s']).to include 'scidoc'
      expect(@sample3['location_code_s']).not_to include 'Lewis Library'
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
    let(:leader) { '1234567890' }
    let(:t400) {{"400"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"t"=>"TITLE"}]}}}
    let(:t440) {{"440"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"t"=>"AWESOME"}, {"a"=>"John"}, {"n"=>"1492"}, {"k"=>"dont ignore"}]}}}

    it 'includes 400 field when 440 missing for series_title_index field' do
      no_440 = @indexer.map_record(MARC::Record.new_from_hash({ 'fields' => [t400], 'leader' => leader }))
      expect(no_440['series_title_index']).to include('TITLE')
    end
    it 'includes 400 and 440 field for series_title_index field' do
      yes_440 = @indexer.map_record(MARC::Record.new_from_hash({ 'fields' => [t400, t440], 'leader' => leader }))
      expect(yes_440['series_title_index']).to match_array(['TITLE', 'John 1492'])
    end
    it 'excludes series_title_index field when no matching values' do
      expect(@sample1['series_title_index']).to be_nil
    end
  end
end
