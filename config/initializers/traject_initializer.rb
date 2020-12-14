require File.join(Rails.root, 'marc_to_solr', 'lib', 'location_processor_service')

LocationProcessorService.process unless Rails.env.test?
TRAJECT_INDEXER ||= LocationProcessorService.build_indexer
