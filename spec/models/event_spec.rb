require 'rails_helper'
require 'fileutils'

RSpec.describe Event, type: :model do
  after do
    described_class.destroy_all
  end

  describe 'Failed dump' do
    before do
      bibs = './spec/fixtures/sample_bib_ids.txt'
      10.times { dump_test_bib_ids(bibs) }
      10.times { test_events(:changed_records) }
      5.times { test_events(:full_dump) }
    end
    it 'creates an unsuccessful event' do
      expect(test_failed_event.success).to be false
    end
  end

  context "When attempting to create duplicate events" do
    let(:message_body) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'aws', 'sqs_incremental_dump.json'))).to_json }

    before do
      described_class.create(message_body:)
    end
    it "does not create a duplicate event" do
      expect do
        described_class.create(message_body:)
      end.not_to change { Event.count }
      expect(Event.count).to eq 1
    end
    it "does not create a duplicate event and raises an error" do
      expect do
        described_class.create!(message_body:)
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Message body has already been taken')
    end
  end
  def dump_test_bib_ids(bibs)
    dump = nil
    Event.record do |event|
      dump = Dump.create(dump_type: :bib_ids)
      dump.event = event
      dump_file = DumpFile.create(dump:, dump_file_type: :bib_ids)
      FileUtils.cp bibs, dump_file.path
      dump_file.save
      dump_file.zip
      dump.dump_files << dump_file
      dump.save
    end
    dump
  end

  def test_events(type)
    dump = nil
    Event.record do |event|
      dump = Dump.create(dump_type: type)
      dump.event = event
      dump.save
    end
    dump
  end

  def test_failed_event
    Event.record do |_event|
      raise Exception.new('test')
    end
  end
end
