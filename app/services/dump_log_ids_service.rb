class DumpLogIdsService
  # Process a dump of MARC files and updates the Dump's delete_id and update_id properties
  def process_dump(id)
    dump = Dump.find(id)
    if dump.dump_type.constant != "CHANGED_RECORDS"
      raise StandardError.new, "Dump is of type #{dump.dump_type.constant}, must be CHANGED_RECORDS"
    end

    delete_ids = []
    update_ids = []
    dump.dump_files.each do |dump_file|
      tar_decompress_file(dump_file.path) do |marc_file|
        file_delete_ids, file_update_ids = process_marc_file(marc_file)
        delete_ids += file_delete_ids
        update_ids += file_update_ids
      end
    end

    dump.delete_ids = delete_ids
    dump.update_ids = update_ids
    dump.save
    Rails.logger.info "Log ID totals for dump #{id}: deleted #{dump.delete_ids.count}, updated #{dump.update_ids.count}."
  end

  private

    def process_marc_file(marc_file)
      delete_ids = []
      update_ids = []
      reader = Nokogiri::XML::Reader(marc_file)
      reader.each do |node|
        if node.name == "record" && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          xml = Nokogiri::XML(node.outer_xml)
          id = xml.xpath("//controlfield[@tag='001']/text()").text
          leader = xml.xpath("//leader/text()").text
          if leader[5] == 'd'
            delete_ids << id
          else
            update_ids << id
          end
        end
      end
      [delete_ids, update_ids]
    end

    def tar_decompress_file(tar_file)
      tar_reader(tar_file).each.map do |entry|
        Tempfile.create(entry.full_name, binmode: true) do |decompressed_tmp|
          decompressed_file = write_chunks(entry, decompressed_tmp)
          entry.close
          yield(decompressed_file)
        end
      end
    end

    def tar_reader(tar_file)
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(tar_file))
      tar_extract.tap(&:rewind)
    end

    def write_chunks(entry, temp_file)
      while (chunk = entry.read(16 * 1024))
        temp_file.write chunk
      end
      temp_file.tap(&:rewind)
    end
end
