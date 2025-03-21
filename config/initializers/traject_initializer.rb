def create_global_indexer_service
  TRAJECT_INDEXER ||= IndexerService.build
end

Rails.application.reloader.to_prepare do
  if Rails.env.test? || Rails.env.development?
    LocationMapsGeneratorService.generate_from_templates
  else
    LocationMapsGeneratorService.generate
  end
  
  create_global_indexer_service unless Rails.env.test?
end
