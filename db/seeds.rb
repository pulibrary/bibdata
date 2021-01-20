require 'yaml'

MARC_LIBERATION_CONFIG['dump_types'].each do |dt|
  DumpType.create(label: dt['label'], constant: dt['constant'])
end

MARC_LIBERATION_CONFIG['dump_file_types'].each do |dft|
  DumpFileType.create(label: dft['label'], constant: dft['constant'])
end
