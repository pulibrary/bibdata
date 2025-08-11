namespace :ephemera do
  desc 'Full reindex ephemera into solr'
  task full_reindex: :environment do
    default_solr_url = Rails.application.config.solr[:url]
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    figgy_url = ENV.fetch('FIGGY_URL', nil)

    if figgy_url.nil? || solr_url.nil?
      puts 'Error: FIGGY_URL and SET_URL environment variables are required'
      exit 1
    end

    documents = BibdataRs::Ephemera.json_ephemera_document(figgy_url)
    BibdataRs::Ephemera.index_string(solr_url, documents)

    puts "Successfully indexed #{documents.length} documents to #{solr_url}"
  end
end
