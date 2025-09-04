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

  desc 'Delete all ephemera records from solr'
  task delete_all_ephemera_records: :environment do
    delete_all_ephemera_records
  end

  desc 'Delete and reindex ephemera into solr'
  task delete_and_reindex_ephemera: :environment do
    Rake::Task['ephemera:delete_all_ephemera_records'].invoke
    Rake::Task['ephemera:full_reindex'].invoke
  end

  def delete_all_ephemera_records
    default_solr_url = Rails.application.config.solr[:url]
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    solr = RSolr.connect(url: solr_url)
    if solr_url.nil?
      puts 'Error: SET_URL environment variables are required'
      exit 1
    end

    match_uuid = 'id:/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/'

    response = solr.get('select', params: { q: match_uuid, fl: 'id' })
    uuids = response['response']['docs'].map { |doc| doc['id'] }
    puts "Deleting #{uuids.length} records with UUIDs:"
    uuids.each { |uuid| puts uuid }

    solr.delete_by_query(match_uuid)
    solr.commit
  end
end
