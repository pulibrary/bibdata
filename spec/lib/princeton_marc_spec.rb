# encoding: UTF-8
require 'json'
require './lib/princeton_marc'
require 'library_stdnums'

describe 'From princeton_marc.rb' do

  describe 'electronic_access_links' do
    before(:all) do
      @url1 = 'google.com'
      @url2 = 'yahoo.com'
      @url3 = 'princeton.edu'
      @long_url = 'http://aol.com/234/asdf/24tdsfsdjf'
      @invalid_url = 'mail.usa not link'
      @l856 = {"856"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"u"=>@url1}, {"y"=>"GOOGLE!"}, {"z"=>"label"} ]}}
      @l856_1 = {"856"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"u"=>@url2}, {"3"=>"Table of contents"} ]}}
      @l856_2 = {"856"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"u"=>@long_url}]}}
      @l856_3 = {"856"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"u"=>@url3}, {"y"=>"text 1"}, {"3"=>"text 2"}]}}
      @l856_4 = {"856"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"u"=>@invalid_url}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@l856, @l856_1, @l856_2, @l856_3, @l856_4] })
      @links = electronic_access_links(@sample_marc)
    end

    it 'returns a hash with the url as the key and its anchor text/label as value' do
      expect(@links[@url1]).to eq(["GOOGLE!", "label"])
      expect(@links[@url2]).to eq(["Table of contents"])
      expect(@links[@url3]).to eq(["text 1: text 2"])
      expect(@links[@long_url]).to eq(["aol.com"])
    end

    it 'skips invalid urls' do
      expect(@links).not_to include(@invalid_url)
    end
  end

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

  describe 'process_names function' do
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

  describe 'process_genre_facet function' do
    before(:all) do
      @g600 = {"600"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"a"=>"Exclude"}, {"v"=>"John"}, {"x"=>"Join"}]}}
      @g630 = {"630"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"x"=>"Fiction."}]}}
      @g655 = {"655"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"a"=>"Culture."}, {"x"=>"Dramatic rendition"}, {"v"=>"Awesome"}]}}
      @g655_2 = {"655"=>{"ind1"=>"", "ind2"=>"7", "subfields"=>[{"a"=>"Poetry"}, {"x"=>"Translations into French"}, {"v"=>"Maps"}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@g600, @g630, @g655, @g655_2] })
      @genres = process_genre_facet(@sample_marc)
    end

    it 'trims punctuation' do
      expect(@genres).to include("Culture")
    end

    it 'excludes $a when not 655' do
      expect(@genres).not_to include("Exclude")
    end

    it 'excludes 2nd indicator of 7' do
      expect(@genres).not_to include("Poetry")
      expect(@genres).not_to include("Maps")
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

  SEPARATOR = '—'
  describe 'process_subject_facet function' do
    before(:all) do
      @s610_ind2_5 = {"600"=>{"ind1"=>"", "ind2"=>"5", "subfields"=>[{"a"=>"Exclude"}]}}
      @s600_ind2_7 = {"600"=>{"ind1"=>"", "ind2"=>"7", "subfields"=>[{"a"=>"Also Exclude"}]}}
      @s600 = {"600"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"a"=>"John."}, {"t"=>"Title"}, {"v"=>"split genre"}, {"d"=>"2015"}]}}
      @s630 = {"630"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"x"=>"Fiction"}, {"y"=>"1492"}, {"z"=>"don't ignore"}, {"t"=>"TITLE"}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@s610_ind2_5, @s600, @s630] })
      @subjects = process_subject_facet(@sample_marc)
    end

    it 'excludes subjects without 0 in the 2nd indicator' do
      expect(@subjects).not_to include("Exclude")
      expect(@subjects).not_to include("Also Exclude")
    end

    it 'only separates v,x,y,z with em dash' do
      expect(@subjects).to include("John. Title#{SEPARATOR}split genre 2015")
      expect(@subjects).to include("Fiction#{SEPARATOR}1492#{SEPARATOR}don't ignore TITLE")
    end
  end

  describe 'process_subject_topic_facet function' do
    before(:all) do
      @s600 = {"600"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"a"=>"John."}, {"x"=>"Join"}, {"t"=>"Title"}, {"d"=>"2015"}]}}
      @s630 = {"630"=>{"ind1"=>"", "ind2"=>"0", "subfields"=>[{"x"=>"Fiction"}, {"y"=>"1492"}, {"z"=>"don't ignore"}, {"v"=>"split genre"}, {"t"=>"TITLE"}]}}
      @sample_marc = MARC::Record.new_from_hash({ 'fields' => [@s600, @s630] })
      @subjects = process_subject_topic_facet(@sample_marc)
    end

    it 'trims punctuation' do
      expect(@subjects).to include("John")
    end

    it 'excludes v and y' do
      expect(@subjects).not_to include("1492")
      expect(@subjects).not_to include("split genre")
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

      @a100 = {"100"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut1}]}}
      @a700_1 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut2}, {"4"=> 'edt'}]}}
      @a700_2 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut3}, {"4"=> 'com'}]}}
      @a700_3 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut4}, {"4"=> 'trl'}]}}
      @a700_4 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut5}, {"4"=> 'aaa'}]}}
      @a700_5 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut6}]}}
      @a700_6 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut7}, {"e"=>'translator.'}]}}
      @a700_7 = {"700"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@aut8}, {"e"=>'ed.'}]}}

      @sample_marc = MARC::Record
                      .new_from_hash({ 'fields' => [@a100, @a700_1, @a700_2,
                                                    @a700_3, @a700_4, @a700_5,
                                                    @a700_6, @a700_7] })
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

      @p260_a = {"260"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@place1}]}}
      @p260_b = {"260"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"b"=>@name1}]}}
      @p260_a_b = {"260"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@place1}, {"b"=>@name1}]}}
      @p264_a = {"264"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@place2}]}}
      @p264_b = {"264"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"b"=>@name2}]}}
      @p264_a_b = {"264"=>{"ind1"=>" ", "ind2"=>" ", "subfields"=>[{"a"=>@place2}, {"b"=>@name2}]}}

      @sample_marc_a = MARC::Record.new_from_hash({ 'fields' => [@p260_a, @p264_a] })
      @sample_marc_b = MARC::Record.new_from_hash({ 'fields' => [@p260_b, @p264_b] })
      @sample_marc_a_b = MARC::Record.new_from_hash({ 'fields' => [@p260_a_b, @p264_a_b] })

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
end
