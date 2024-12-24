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

  context 'when MD5 is populated' do
    it "doesn't re-call it on save" do
      subject.save
      allow(Digest::MD5).to receive(:new)

      subject.save

      expect(Digest::MD5).not_to have_received(:new)
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
    it 'returns true for :recap_records type' do
      df = described_class.new(dump_file_type: :recap_records)
      expect(df.recap_record_type?).to be true
    end

    it 'returns true for :recap_records_full type' do
      df = described_class.new(dump_file_type: :recap_records_full)
      expect(df.recap_record_type?).to be true
    end

    it 'otherwise returns false' do
      df = described_class.new(dump_file_type: :bib_records)
      expect(df.recap_record_type?).to be false
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

  describe '#tar_decompress_file' do
    let(:dump_file) { described_class.create(path: file_path) }

    context "with a file that doesn't exist" do
      let(:file_path) { 'spec/fixtures/files/alma/do_not_create_me.gz' }

      it 'raises an error' do
        expect { |b| dump_file.tar_decompress_file(&b) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'with a .tar.gz file' do
      let(:file_path) { 'spec/fixtures/files/alma/full_dump/1.xml.tar.gz' }

      it 'yields a block' do
        expect { |b| dump_file.tar_decompress_file(&b) }.to yield_with_args
      end
    end
  end
end
