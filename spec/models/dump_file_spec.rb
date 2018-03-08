require 'rails_helper'
require 'fileutils'

RSpec.describe DumpFile, type: :model do

  subject do
    instance = described_class.create
    FileUtils.touch(instance.path)
    instance
  end

  after(:each) do
    File.delete(subject.path) unless subject.nil? || !File.exists?(subject.path)
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
