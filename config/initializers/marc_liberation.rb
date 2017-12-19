require 'yaml'

MARC_LIBERATION_CONFIG ||= YAML.load(ERB.new(File.read("#{Rails.root}/config/marc_liberation.yml")).result)
