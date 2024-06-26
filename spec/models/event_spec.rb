require 'rails_helper'
require 'fileutils'

RSpec.describe Event, type: :model do
  before(:all) do
    bibs = './spec/fixtures/sample_bib_ids.txt'
    10.times { dump_test_bib_ids(bibs) }
    10.times { test_events(:changed_records) }
    5.times { test_events(:full_dump) }
  end

  after(:all) do
    described_class.destroy_all
  end

  describe 'Failed dump' do
    it 'creates an unsuccessful event' do
      expect(test_failed_event.success).to be false
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
