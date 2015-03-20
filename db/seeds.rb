require 'yaml'

cfg = YAML.load(File.read(Rails.root.join('config/marc_liberation.yml')))

cfg['dump_types'].each do |dt|
  DumpType.create(label: dt['label'], constant: dt['constant'])
end

cfg['dump_file_types'].each do |dft|
  DumpFileType.create(label: dft['label'], constant: dft['constant'])
end
