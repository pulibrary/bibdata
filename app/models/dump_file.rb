require 'zlib'
require 'digest'

class DumpFile < ActiveRecord::Base
  include FilePathGenerator

  belongs_to :dump
  belongs_to :dump_file_type

  after_create do
    self.path = generate_fp
    self.save
  end

  before_save do
    unless self.path.nil? || !File.exist?(self.path)
      self.md5 = File.open(self.path, 'rb') do |io|
        digest = Digest::MD5.new
        buf = ''
        while io.read(4096, buf)
          digest.update(buf)
        end
        digest
      end
    end

  end

  before_destroy do
    File.delete(self.path) if File.exist?(self.path)
  end

  def zipped?
    self.path.ends_with?('.gz')
  end

  def zip
    unless self.zipped?
      gz_path = "#{self.path}.gz"
      uncompressed_path = self.path
      Zlib::GzipWriter.open(gz_path) do |gz|
        File.open(uncompressed_path) do |fp|
          while chunk = fp.read(16 * 1024) do
            gz.write chunk
          end
        end
        gz.close
      end
      self.path = gz_path
      File.delete(uncompressed_path)
      self.save
    end
    self
  end

  def unzip
    if self.zipped?
      uncompressed_path = self.path.sub(/\.gz$/, '')
      gz_path = self.path

      Zlib::GzipReader.open(gz_path) do |gz|
        File.open(uncompressed_path, 'w') do |fp|
          while chunk = gz.read(16 * 1024) do
            fp.write chunk
          end
        end
        gz.close
      end

      self.path = uncompressed_path
      File.delete(gz_path)
      self.save
    end
    self
  end

end
