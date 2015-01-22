require 'date'

describe VoyagerHelpers::SyncFu do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../fixtures') }
  let(:earlier_file) { File.join(fixtures_dir, 'earlier_id_dump.txt') }
  let(:later_file) { File.join(fixtures_dir, 'later_id_dump.txt') }
  let(:subject) { described_class }

  describe '#compare_id_dumps' do

    it 'sorts the entries as expected' do
      now = DateTime.now.new_offset(0)
      report = VoyagerHelpers::SyncFu.compare_id_dumps(earlier_file, later_file, now)
      expected = {
        create: [ 
          {
            id: '11',
            datetime: DateTime.parse('2000-06-08T00:00:00-05:00').new_offset(0)
          }, {
            id: '6',
            datetime: DateTime.parse('2013-04-12T13:40:57-05:0').new_offset(0)
          } 
        ],
        update: [ 
          {
            id: '1',
            datetime: DateTime.parse('2012-06-21T11:40:38-05:00').new_offset(0)
          }, 
          {
            id: '8',
            datetime: DateTime.parse('2012-07-06T10:22:00-05:00').new_offset(0)
          }
        ],
        delete: [ 
          { id: '2', datetime: now }, 
          { id: '5', datetime: now } 
        ]
      }
      expect(report).to eq expected
    end

    it 'does not raise an error if we don\'t supply the time' do
      expect {
        VoyagerHelpers::SyncFu.compare_id_dumps(earlier_file, later_file)
      }.to_not raise_error
    end

    it 'will supply a delete date if we don\'t supply the time' do
      report = VoyagerHelpers::SyncFu.compare_id_dumps(earlier_file, later_file)
      expect(report[:delete][0][:datetime]).to be_a DateTime
    end
  end
end










