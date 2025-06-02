namespace :ephemera do
  desc 'Full reindex ephemera into solr'
  task full_reindex: :environment do
    default_solr_url = 'http://localhost:8983/solr/blacklight-core-development'
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    figgy_url = ENV.fetch('FIGGY_URL', nil)
    BibdataRs::Ephemera.json_ephemera_document(figgy_url)
  end
end
