if Rails.env.test? || Rails.env.development?
  LocationMapsGeneratorService.generate_from_templates
else
  LocationMapsGeneratorService.generate
end

TRAJECT_INDEXER ||= IndexerService.build
