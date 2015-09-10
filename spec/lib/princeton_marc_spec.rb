require 'json'
require './lib/princeton_marc'
require 'library_stdnums'

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
      @non_oclc_num = '12345678'
      @non_oclc_776w = {"776"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"w"=>@non_oclc_num}]}}
      @oclc_num = '(OCoLC)on9990014350'
      @oclc_776w = {"776"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"w"=>@oclc_num}]}}
      @oclc_num2 = '(OCoLC)on9990014351'
      @oclc_num3 = '(OCoLC)on9990014352'
      @oclc_787w = {"787"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"w"=>@oclc_num2}, {"z"=>@oclc_num3}]}}
      @oclc_num4 = '(OCoLC)on9990014353'
      @oclc_035a = {"035"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"a"=>@oclc_num4}]}}
      @issn_num = "0378-5955"
      @issn_022 = {"022"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"l"=>@issn_num}, {"y"=>@issn_num}]}}
      @issn_num2 = "1234-5679"
      @issn_776x = {"776"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"x"=>@issn_num2}]}}
      @isbn_num = '0-9752298-0-X'
      @isbn_776z = {"776"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"z"=>@isbn_num}]}}
      @isbn_num2 = 'ISBN: 978-0-306-40615-7'
      @isbn_num2_10d = '0-306-40615-2'
      @isbn_020 = {"020"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"a"=>@isbn_num2}, {"z"=>@isbn_num2_10d}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@non_oclc_776w, @oclc_776w, @oclc_787w, @oclc_035a, @issn_022, @issn_776x, @isbn_776z, @isbn_020] })
      @linked_nums = other_versions(@sample_marc)
    end

    it 'includes isbn, issn, oclc nums for expected fields/subfields' do
      expect(@linked_nums).to include(oclc_normalize(@oclc_num, prefix: true))
      expect(@linked_nums).to include(oclc_normalize(@oclc_num2, prefix: true))
      expect(@linked_nums).to include(oclc_normalize(@oclc_num4, prefix: true))
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

    it 'excludes non oclc in expected oclc subfield' do
      expect(@linked_nums).not_to include(oclc_normalize(@non_oclc_num, prefix: true))
    end
  end

  describe 'process_names function'
    before(:all) do
      @t100 = {"100"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"a"=>"John"}, {"d"=>"1492"}, {"t"=>"TITLE"}, {"k"=>"ignore"}]}}
      @t700 = {"700"=>{"ind1"=>"", "ind2"=>" ", "subfields"=>[{"a"=>"John"}, {"d"=>"1492"}, {"k"=>"don't ignore"}, {"t"=>"TITLE"}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@t100, @t700] })
    end

    it 'strips subfields that appear after subfield $t' do
      names = process_names(@sample_marc)
      expect(names).to include("John 1492")
      expect(names).to include("John 1492 don't ignore")
      expect(names).not_to include("John 1492 ignore")
    end
end
