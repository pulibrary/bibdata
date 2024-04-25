require "rails_helper"
# This class is currently defined in the aws_sqs_poller.rb file, so auto-loaders can't find it
require 'app/services/aws_sqs_poller.rb'

RSpec.describe AlmaDumpFactory do
  context 'looking at the dump more than once' do
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_recap_incremental_dump.json'))) }

    it 'only instantiates one dump' do
      dump = AlmaDumpFactory.bib_dump(message_body)
      expect(dump).to be_an_instance_of(Dump)
      expect(Dump.count).to eq(1)
      expect { dump }.not_to change(Dump, :count)
    end
  end
end
