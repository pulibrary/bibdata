require 'json'
require 'traject'
require 'faraday'
require 'time'
require 'iso-639'
require 'pry-byebug'

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
    @authority1 = @indexer.map_record(fixture_record('sample_auth'))
  end

  describe 'the auth_001_s field' do
    it 'returns 001 field with no spaces' do
      expect(@authority1['auth_001_s']).to eq(['10000001'])
    end
  end
end
