# frozen_string_literal: true

class DataSeeder
  attr_accessor :logger, :dump_types, :dump_file_types

  def initialize(logger = Logger.new(STDOUT))
    @logger = logger
    @dump_types = MARC_LIBERATION_CONFIG['dump_types']
    @dump_file_types = MARC_LIBERATION_CONFIG['dump_file_types']
  end

  def generate_dump_types
    dump_types.each do |dt|
      DumpType.find_or_create_by(label: dt['label'], constant: dt['constant'])
    end
    logger.info "Created #{dump_types.count} dump types"
  end

  def generate_dump_file_types
    dump_file_types.each do |dft|
      DumpFileType.find_or_create_by(label: dft['label'], constant: dft['constant'])
    end
    logger.info "Created #{dump_file_types.count} dump file types"
  end
end
