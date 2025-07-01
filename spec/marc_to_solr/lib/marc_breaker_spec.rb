require 'spec_helper'
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

RSpec.describe MarcBreaker do
  it 'converts a marc record to the MarcBreaker format' do
    reader = MARC::XMLReader.new File.expand_path('../../fixtures/marc_to_solr/9914141453506421.mrx', __dir__)
    original_record = reader.first
    breaker = described_class.break original_record
    # rubocop:disable Layout/TrailingWhitespace -- the data contains trailing whitespace
    expect(breaker).to eq(
      <<~'END_MARC_BREAKER_RECORD'.strip
        =LDR 01250ccm a2200313   4500
        =005 20200803230550.0
        =008 741028s1973    gw snz         n         
        =001 9914141453506421
        =010 \\$a   74211217  
        =035 \\$a(OCoLC)ocm01058581$0(uri) http://www.worldcat.org/oclc/01058581
        =035 \\$9CEF8507TS
        =035 \\$a1414145
        =035 \\$a(NjP)1414145-princetondb
        =040 \\$aDLC$cPAU$dOCL$dENG$dPUL
        =041 0\$ggerengfre
        =048 \\$aka01
        =050 0\$aM23$b.L774 B min., 1973
        =100 1\$aLiszt, Franz,$d1811-1886.$0http://id.loc.gov/authorities/names/n79079048$0(uri) http://id.loc.gov/authorities/names/n79079048$0(uri) http://viaf.org/viaf/sourceID/LC|n79079048
        =240 10$aSonatas,$mpiano,$rB minor
        =245 00$aSonate h-moll,$cnach dem Autograph und der Erstausg. Hrsg. von Ernst Herttrich. Fingersatz von Hans-Martin Theopold.
        =260 \\$aMünchen,$bG. Henle Verlag$c[1973]
        =300 \\$a39 p.$c32 cm.
        =500 \\$aPref. in German, English, and French.
        =650 \0$aSonatas (Piano)$0http://id.loc.gov/authorities/subjects/sh85124927$0(uri) http://id.loc.gov/authorities/subjects/sh85124927
        =655 \7$aSonatas.$2lcgft$0http://id.loc.gov/authorities/genreForms/gf2014027099$0(uri) http://id.loc.gov/authorities/genreForms/gf2014027099
        =655 \7$aSonatas.$2lcgft$0http://id.loc.gov/authorities/genreForms/gf2014027099$0(uri) http://id.loc.gov/authorities/genreForms/gf2014027099
        =700 1\$aHerttrich, Ernst,$d1942-$0http://id.loc.gov/authorities/names/n81047600$0(uri) http://id.loc.gov/authorities/names/n81047600$0(uri) http://viaf.org/viaf/sourceID/LC|n81047600
        =700 1\$aTheopold, Hans-Martin.$0http://id.loc.gov/authorities/names/n78015433$0(uri) http://id.loc.gov/authorities/names/n78015433$0(uri) http://viaf.org/viaf/sourceID/LC|n78015433
        =947 \\$aCEF8507
        =911 \\$a19990326
        =950 \\$c2021-07-31 19:11:22 US/Eastern$b2021-07-13 02:46:53 US/Eastern$afalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783950006421
        =952 \\$a2021-07-13 06:46:53$822679783950006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783970006421
        =952 \\$a2021-07-13 06:46:53$822679783970006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679784070006421
        =952 \\$a2021-07-13 06:46:53$822679784070006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bmendel$cstacks$hM23.L5S6 1973q$kOversize$822679784090006421
        =952 \\$a2021-07-13 06:46:53$822679784090006421$bMendel Music Library$cstacks: Mendel Music Library$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679784010006421
        =952 \\$a2021-07-13 06:46:53$822679784010006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783870006421
        =952 \\$a2021-07-13 06:46:53$822679783870006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783890006421
        =952 \\$a2021-07-13 06:46:53$822679783890006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783990006421
        =952 \\$a2021-07-13 06:46:53$822679783990006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783930006421
        =952 \\$a2021-07-13 06:46:53$822679783930006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bmendel$cstacks$hM23.L5S6 1973q$kOversize$822679784050006421
        =952 \\$a2021-07-13 06:46:53$822679784050006421$bMendel Music Library$cstacks: Mendel Music Library$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679783910006421
        =952 \\$a2021-07-13 06:46:53$822679783910006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =852 00$bannex$cstacks$hM23.L5S6 1973q$kOversize$822679784030006421
        =952 \\$a2021-07-13 06:46:53$822679784030006421$bForrestal Annex$cstacks: Annex Stacks$efalse
        =876 \\$022679783870006421$a23679783860006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094724$t10$yannex
        =876 \\$022679783950006421$a23679783940006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094682$t6$yannex
        =876 \\$022679784070006421$a23679784060006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094674$t5$yannex
        =876 \\$022679784010006421$a23679784000006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094641$t2$yannex
        =876 \\$022679783890006421$a23679783880006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094716$t9$yannex
        =876 \\$022679784090006421$a23679784080006421$j1$zstacks$d2021-07-13 06:46:53$p32101003526165$t1$ymendel
        =876 \\$022679783990006421$a23679783980006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094658$t3$yannex
        =876 \\$022679783910006421$a23679783900006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094708$t8$yannex
        =876 \\$022679783930006421$a23679783920006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094690$t7$yannex
        =876 \\$022679784030006421$a23679784020006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094914$t1$yannex
        =876 \\$022679784050006421$a23679784040006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094765$t2$ymendel
        =876 \\$022679783970006421$a23679783960006421$j1$zstacks$d2021-07-13 06:46:53$p32101030094666$t4$yannex
      END_MARC_BREAKER_RECORD
    )
    # rubocop:enable Layout/TrailingWhitespace
  end

  it 'can handle invalid multi-byte indicators' do
    marc_xml_with_invalid_indicator = <<~XML
      <record>
        <leader>05654nam a2200397zu 4500</leader>
        <datafield tag="700" ind1="1" ind2="§">
          <subfield code="a">Amdam, Roar,</subfield>
          <subfield code="d">1951-</subfield>
          <subfield code="0">(DLC)n 97006361</subfield>
          <subfield code="4">hnr</subfield>
        </datafield>
      </record>
    XML
    reader = MARC::XMLReader.new(StringIO.new(marc_xml_with_invalid_indicator))
    original_record = reader.first
    breaker = described_class.break original_record
    expect(breaker).to eq(
      <<~'END_MARC_BREAKER_RECORD'.strip
        =LDR 05654nam a2200397zu 4500
        =700 1\$aAmdam, Roar,$d1951-$0(DLC)n 97006361$4hnr
      END_MARC_BREAKER_RECORD
    )
  end

  it 'removes fields with a blank tag' do
    marc_xml_with_blank_tag = <<~END_MARC_XML
      <record>
        <leader>05654nam a2200397zu 4500</leader>
        <datafield tag="" ind1="1" ind2="7">
          <subfield code="a">Truesdell, Edward D.</subfield>
          <subfield code="4">dnr</subfield>
          <subfield code="2">local</subfield>
        </datafield>
      </record>
    END_MARC_XML
    reader = MARC::XMLReader.new(StringIO.new(marc_xml_with_blank_tag))
    original_record = reader.first
    breaker = described_class.break original_record
    expect(breaker).to eq('=LDR 05654nam a2200397zu 4500')
  end

  it 'replaces invalid subfield code with an empty string' do
    marc_xml_with_blank_tag = <<~END_MARC_XML
      <record>
        <leader>05654nam a2200397zu 4500</leader>
        <datafield tag="082" ind1="0" ind2="">
          <subfield code="ǂ">2 22</subfield>
          <subfield code="4">dnr</subfield>
        </datafield>
      </record>
    END_MARC_XML
    reader = MARC::XMLReader.new(StringIO.new(marc_xml_with_blank_tag))
    original_record = reader.first
    breaker = described_class.break original_record
    expect(breaker).to eq("=LDR 05654nam a2200397zu 4500\n=082 0\\$4dnr")
  end

  it 'is faster than the XML serialization from the Ruby Marc gem' do
    reader = MARC::XMLReader.new File.expand_path('../../fixtures/marc_to_solr/9914141453506421.mrx', __dir__)
    original_record = reader.first
    expect { described_class.break original_record }.to(perform_faster_than { original_record.to_xml.to_s })
  end
end
