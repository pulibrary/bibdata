require 'rails_helper'
require 'fileutils'

RSpec.describe DumpFile, type: :model do
  subject do
    instance = described_class.create
    FileUtils.touch(instance.path)
    instance
  end

  after(:each) do
    File.delete(subject.path) unless subject.nil? || !File.exist?(subject.path)
  end

  describe 'when a new instance is created' do
    it 'populates :path' do
      expect(subject.path).to_not be_nil
    end
  end

  describe 'when an instance is destroyed' do
    it 'the file at :path is deleted' do
      path = subject.path
      subject.destroy
      expect(File.exist?(path)).to be_falsey
    end
  end

  describe '#recap_record_type?' do
    let(:recap_record_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS') }
    let(:recap_record_full_type) { DumpFileType.find_by(constant: 'RECAP_RECORDS_FULL') }
    let(:other_type) { DumpFileType.create }
    it 'returns true for RECAP_RECORDS type' do
      df = DumpFile.new(dump_file_type: recap_record_type)
      expect(df.recap_record_type?).to eq true
    end
    it 'returns true for RECAP_RECORDS_FULL type' do
      df = DumpFile.new(dump_file_type: recap_record_full_type)
      expect(df.recap_record_type?).to eq true
    end
    it 'otherwise returns false' do
      df = DumpFile.new(dump_file_type: other_type)
      expect(df.recap_record_type?).to eq false
    end
  end

  describe '#zip' do
    it 'changes the file path to include gz' do
      path = subject.path
      FileUtils.touch(subject.path)
      subject.zip
      expect(subject.path).to eq "#{path}.gz"
    end
  end

  describe '#unzip' do
    it 'changes the file path to exclude gz' do
      subject.zip
      subject.unzip
      expect(subject.path.end_with?('.gz')).to be_falsey
    end
  end
end
