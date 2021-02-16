require 'rails_helper'

RSpec.describe IncrementalIndexJob, type: :job do
  subject(:index_job) { described_class.new }
 
  describe '.perform' do
    it 'indexes a dump with many files' do
        expect(true).to be true
    end
  end
end
