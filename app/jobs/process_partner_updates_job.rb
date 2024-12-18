class ProcessPartnerUpdatesJob < ApplicationJob
  def perform(dump_id:, files:, file_prefix:, update_directory: '', scsb_file_dir: '')
    @inv_xml = []
    @tab_newline = []
    @leader = []
    @composed_chars = []
    @bad_utf8 = []
    xml_files = []
    files.each do |file|
      filename = File.basename(file, '.zip')
      filename.gsub!(/^[^_]+_([0-9]+)_([0-9]+).*$/, '\1_\2')
      file_increment = 1
      Zip::File.open(file) do |zip_file|
        zip_file.each do |entry|
          target = "#{update_directory}/#{filename}_#{file_increment}.xml"
          xml_files << target
          entry.extract(target)
          file_increment += 1
        end
      end
      File.unlink(file)
    end
    xml_files.each do |file|
      filename = File.basename(file)
      reader = MARC::XMLReader.new(file.to_s, external_encoding: 'UTF-8')
      filepath = "#{scsb_file_dir}/#{file_prefix}#{filename}"
      writer = MARC::XMLWriter.new(filepath)
      reader.each { |record| writer.write(process_record(record)) }
      writer.close
      File.unlink(file)
      attach_dump_file(dump_id:, filepath:)
    end
  end

  def process_record(record)
    record = field_delete(['856', '959'], record)
    record.leader[5] = 'c' if record.leader[5].eql?('d')
    if bad_utf8?(record)
      @bad_utf8 << record['001']
      record = bad_utf8_fix(record)
    end
    if invalid_xml_chars?(record)
      @inv_xml << record['001']
      record = invalid_xml_fix(record)
    end
    if tab_newline_char?(record)
      @tab_newline << record['001']
      record = tab_newline_fix(record)
    end
    if leader_errors?(record)
      @leader << record['001']
      record = leaderfix(record)
    end
    if composed_chars_errors?(record)
      @composed_chars << record['001']
      record = composed_chars_normalize(record)
    end
    record = extra_space_fix(record)
    empty_subfield_fix(record)
  end

  def attach_dump_file(dump_id:, filepath:, dump_file_type: :recap_records_full)
    df = DumpFile.create(dump_file_type:, path: filepath)
    df.zip
    df.save!
    dump = Dump.find(dump_id)
    dump.dump_files << df
    dump.save!
  end
end
