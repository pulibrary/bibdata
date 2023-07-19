require 'zlib'
require 'digest'
require 'rubygems/package'

class DumpFile < ActiveRecord::Base
  belongs_to :dump
  belongs_to :dump_file_type
  enum index_status: { enqueued: 0, started: 1, done: 2 }

  after_create do
    self.path = generate_fp if path.nil?
    save
  end

  before_save do
    unless path.nil? || !File.exist?(path) || md5.present?
      self.md5 = File.open(path, 'rb') do |io|
        # nosemgrep
        digest = Digest::MD5.new
        buf = ''
        digest.update(buf) while io.read(4096, buf)
        digest
      end
    end
  end

  before_destroy do
    File.delete(path) if File.exist?(path)
  end

  def recap_record_type?
    [
      DumpFileType.find_by(constant: 'RECAP_RECORDS'),
      DumpFileType.find_by(constant: 'RECAP_RECORDS_FULL')
    ].include? dump_file_type
  end

  def zipped?
    path.ends_with?('.gz')
  end

  def zip
    unless zipped?
      gz_path = "#{path}.gz"
      uncompressed_path = path
      Zlib::GzipWriter.open(gz_path) do |gz|
        File.open(uncompressed_path) do |fp|
          while chunk = fp.read(16 * 1024)
            gz.write chunk
          end
        end
        gz.close
      end
      self.path = gz_path
      File.delete(uncompressed_path)
      save
    end
    self
  end

  def unzip
    if zipped?
      uncompressed_path = path.sub(/\.gz$/, '')
      gz_path = path

      Zlib::GzipReader.open(gz_path) do |gz|
        File.open(uncompressed_path, 'wb') do |fp|
          while chunk = gz.read(16 * 1024)
            fp.write chunk
          end
        end
        gz.close
      end

      self.path = uncompressed_path
      File.delete(gz_path)
      save
    end
    self
  end

  def generate_fp
    File.join(MARC_LIBERATION_CONFIG['data_dir'], Time.now.to_i.to_s)
  end

  # Alma files are tarred and g-zipped, so you have to do both.
  def tar_decompress_file
    tar_reader.each.map do |entry|
      Tempfile.create(decompressed_filename(entry), binmode: true) do |decompressed_tmp|
        decompressed_file = write_chunks(entry, decompressed_tmp)
        entry.close
        yield(decompressed_file)
      end
    end
  end

  def tar_reader
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(path))
    tar_extract.tap(&:rewind)
  end

  def write_chunks(entry, temp_file)
    while (chunk = entry.read(16 * 1024))
      temp_file.write chunk
    end
    temp_file.tap(&:rewind)
  end

  def decompressed_filename(entry)
    file_name, decompress_extension = entry.full_name.split(".")
    decompress_extension ||= "xml"
    ["full_reindex_file_unzip_#{file_name}", "." + decompress_extension]
  end
end
