require 'yaml'

cfg = YAML.load(File.read(Rails.root.join('config/marc_liberation.yml')))
cfg['dump_types'].each do |dt|
  DumpType.create(label: dt['label'], constant: dt['constant'])
end
