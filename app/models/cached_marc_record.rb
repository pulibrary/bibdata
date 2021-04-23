class CachedMarcRecord < ActiveRecord::Base
  def parsed_record
    MARC::XMLReader.new(StringIO.new(marc), external_encoding: 'UTF-8').first
  end
end
