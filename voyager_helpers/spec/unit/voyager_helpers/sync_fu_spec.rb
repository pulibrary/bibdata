require 'spec_helper'
require 'date'

describe VoyagerHelpers::SyncFu do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../fixtures') }
  let(:earlier_file) { File.join(fixtures_dir, 'earlier_id_dump.txt') }
  let(:later_file) { File.join(fixtures_dir, 'later_id_dump.txt') }
  let(:subject) { described_class }


  describe '#compare_id_dumps' do

    it 'sorts the entries as expected' do
      now = DateTime.now.new_offset(0)
      report = subject.compare_id_dumps(earlier_file, later_file, now)
      expected_created = [
        {
          id: '6',
          lastmod: DateTime.parse('2013-04-12T13:40:57-05:0').new_offset(0)
        }, {
          id: '11',
          lastmod: DateTime.parse('2000-06-08T00:00:00-05:00').new_offset(0)
        }
      ]
      expected_updated = [
        {
          id: '1',
          lastmod: DateTime.parse('2012-06-21T11:40:38-05:00').new_offset(0)
        },
        {
          id: '8',
          lastmod: DateTime.parse('2012-07-06T10:22:00-05:00').new_offset(0)
        }
      ]
      expected_deleted = [
        { id: '2', lastmod: now },
        { id: '5', lastmod: now }
      ]
      expect(report.created).to eq expected_created
      expect(report.updated).to eq expected_updated
      expect(report.deleted).to eq expected_deleted
    end

    it 'does not raise an error if we don\'t supply the time' do
      expect {
        subject.compare_id_dumps(earlier_file, later_file)
      }.to_not raise_error
    end

    it 'will supply a delete date if we don\'t supply the time' do
      report = subject.compare_id_dumps(earlier_file, later_file)
      expect(report.deleted[0][:lastmod]).to be_a DateTime
    end
  end

end











