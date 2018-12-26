require 'json'
require 'traject'
require 'faraday'
require 'time'
require 'iso-639'

describe 'From authority_traject_config.rb' do
  let(:leader) { '1234567890' }

  def fixture_record(fixture_name)
    f = File.expand_path("../../fixtures/#{fixture_name}.mrc", __FILE__)
    MARC::Reader.new(f).first
  end

  before(:all) do
    c = File.expand_path('../../../lib/authority_traject_config.rb', __FILE__)
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'the vocab_type_s field' do
    context "when tag 155 is present" do
      let(:main_field_tag_010) do
        {
          '010' => {
            "subfields" => [{ "a" => "sh2008025706" }]
          }
        }
      end
      let(:main_field_tag_155) do
        {
          "155" => {
            "subfields" => [{ "a" => "Historical films" }, { "v" => "Parodies, imitations, etc. [proposed]" }]
          }
        }
      end
      let(:vocab_type_subjects) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [main_field_tag_010, main_field_tag_155], 'leader' => leader)) }
      it 'returns type geneForms' do
        expect(vocab_type_subjects['vocab_type_s']).to eq(['genreForms'])
      end
    end
    context "when tag 150 is present" do
      let(:main_field_tag_010) do
        {
          '010' => {
            "subfields" => [{ "a" => "sh2008025706" }]
          }
        }
      end
      let(:main_field_tag_150) do
        {
          "150" => {
            "subfields" => [{ "a" => "Maxims, Paraguayan" }]
          }
        }
      end
      let(:vocab_type_subjects) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [main_field_tag_010, main_field_tag_150], 'leader' => leader)) }
      it 'returns type subjects' do
        expect(vocab_type_subjects['vocab_type_s']).to eq(['subjects'])
      end
    end
    context "when tag 150 is present but 010 is not" do
      let(:main_field_tag_150) do
        {
          "150" => {
            "subfields" => [{ "a" => "Maxims, Paraguayan" }]
          }
        }
      end
      let(:vocab_type_subjects) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [main_field_tag_150], 'leader' => leader)) }
      it 'does not return a vocab_type_s field' do
        expect(vocab_type_subjects['vocab_type_s']).to be_falsy
      end
    end
  end

  describe 'the id field' do
    let(:field_001) do
      {
        '001' => "sh2012002104"
      }
    end
    let(:main_field_tag_010) do
      {
        '010' => {
          "subfields" => [{ "a" => "sh2012002104" }]
        }
      }
    end
    let(:main_field_tag_150) do
      {
        "150" => {
          "subfields" => [{ "a" => "International agencies", "x" => "Law and legislation" }]
        }
      }
    end
    let(:auth_record) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [field_001, main_field_tag_010], 'leader' => leader)) }
    it 'returns the id field' do
      expect(auth_record['id']).to eq(['sh2012002104'])
    end
  end

  describe 'the auth_010_s field' do
    let(:field_001) do
      {
        '001' => "sh2012002104"
      }
    end
    let(:main_field_tag_010) do
      {
        '010' => {
          "subfields" => [{ "a" => "sh2012002104" }]
        }
      }
    end
    let(:main_field_tag_150) do
      {
        "150" => {
          "subfields" => [{ "a" => "Maxims, Paraguayan" }]
        }
      }
    end
    let(:auth_010_s_record) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [main_field_tag_010, field_001], 'leader' => leader)) }
    it 'returns the auth_010_s' do
      expect(auth_010_s_record['auth_010_s']).to eq(['sh2012002104'])
    end
  end
end
