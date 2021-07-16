require 'rails_helper'

RSpec.describe IndexerService do
  subject { described_class.build }

  it { is_expected.to be_a(Traject::Indexer) }
end
