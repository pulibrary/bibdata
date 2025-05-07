namespace :theses do
    desc 'Exports all theses as solr json docs to FILEPATH'
    task cache_theses: :environment do
    BibdataRs::Theses::Fetcher.write_all_collections_to_cache
    end
end
