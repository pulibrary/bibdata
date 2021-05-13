require 'yaml'

MARC_LIBERATION_CONFIG['dump_types'].each do |dt|
  DumpType.find_or_create_by(label: dt['label'], constant: dt['constant'])
end

MARC_LIBERATION_CONFIG['dump_file_types'].each do |dft|
  DumpFileType.find_or_create_by(label: dft['label'], constant: dft['constant'])
end
