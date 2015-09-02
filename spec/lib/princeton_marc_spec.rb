require 'json'
require './lib/princeton_marc'

describe 'From princeton_marc.rb' do

  describe 'standard_no_hash with keys based on the first indicator' do
    before(:all) do
      @key_for_3 = "International Article Number"
      @key_for_4 = "Serial Item and Contribution Identifier"
      @default_key = "Other standard number"
      @sub2_key = "Special number"
      @ind1_3 = {"024"=>{"ind1"=>"3", "ind2"=>" ", "subfields"=>[{"a"=>'111'}]}}
      @ind1_4 = {"024"=>{"ind1"=>"4", "ind2"=>" ", "subfields"=>[{"a"=>'123'}]}}
      @ind1_4_second = {"024"=>{"ind1"=>"4", "ind2"=>" ", "subfields"=>[{"a"=>'456'}]}}
      @ind1_8 = {"024"=>{"ind1"=>"8", "ind2"=>" ", "subfields"=>[{"a"=>'654'}]}}
      @ind1_blank = {"024"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>'321'}]}}
      @ind1_7 = {"024"=>{"ind1"=>"7", "ind2"=>" ", "subfields"=>[{"a"=>'789'}, "2"=>@sub2_key]}}
      @missing_sub2 = {"024"=>{"ind1"=>"7", "ind2"=>" ", "subfields"=>[{"a"=>'987'}]}}
      @empty_sub2 = {"024"=>{"ind1"=>"7", "ind2"=>" ", "subfields"=>[{"a"=>'000', "2"=>''}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@ind1_3, @ind1_4, @ind1_4_second, @ind1_8, @ind1_blank, @ind1_7, @missing_sub2, @empty_sub2] })
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

  describe 'oclc_s normalize substituting non digits should be sufficient' do
    it 'without prefix' do
      expect(oclc_normalize("(OCoLC)882089266")).to eq("882089266")
    end

    it 'with prefix' do
      expect(oclc_normalize("(OCoLC)on9990014350")).to eq("9990014350")
      expect(oclc_normalize("(OCoLC)ocn899745778")).to eq("899745778")
      expect(oclc_normalize("(OCoLC)ocm00012345")).to eq("00012345")
    end
  end
end
