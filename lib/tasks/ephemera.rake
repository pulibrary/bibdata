namespace :ephemera do
  desc 'Full reindex ephemera into solr'
  task full_reindex: :environment do
    default_solr_url = 'http://localhost:8983/solr/'
    default_collection = 'blacklight-core-development'
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    figgy_url = ENV.fetch('FIGGY_URL', nil)
    collection = ENV.fetch('COLLECTION', default_collection)
    
    if figgy_url.nil? || collection.nil? || solr_url.nil?
      puts "Error: FIGGY_URL, COLLECTION, and SET_URL environment variables are required"
      exit 1
    end  

    documents = BibdataRs::Ephemera.json_ephemera_document(figgy_url)
    BibdataRs::Ephemera.index(solr_url, collection, documents)

    puts "Successfully indexed #{documents.length} documents to #{solr_url}/#{collection}"
  end
end
