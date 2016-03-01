require 'json'

f = File.read("#{File.dirname(__FILE__)}/../../public/context.json")
RELATORS ||= JSON.parse(f)['@context'].select { |k,v| (v['@id'] || '').start_with? 'mrel:' }.keys
