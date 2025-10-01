require 'faraday'
require 'json'
require 'lightly'
require 'rsolr'
require 'time'
require 'zlib'

require_relative '../../marc_to_solr/lib/cache_adapter'
require_relative '../../marc_to_solr/lib/cache_manager'
require_relative '../../marc_to_solr/lib/cache_map'
require_relative '../../marc_to_solr/lib/composite_cache_map'

default_bibdata_url = 'https://bibdata-staging.lib.princeton.edu'
bibdata_url = ENV.fetch('BIBDATA_URL', nil) || default_bibdata_url

default_solr_url = 'http://localhost:8983/solr/blacklight-core-development'
commit = '-s solrj_writer.commit_on_close=true'
binary = '-t binary'

bibdata_connection = Faraday.new(url: bibdata_url) do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

desc 'Index MARC against SET_URL, set NO_COMMIT to 1 to skip commit'
task :index do
  if ENV['MARC']
    url_arg = ENV['SET_URL'] ? "-u #{ENV.fetch('SET_URL', nil)}" : ''
    fixtures = ENV.fetch('MARC', nil)
    if ENV.fetch('NO_COMMIT', nil) && ENV.fetch('NO_COMMIT', nil) == '1'
      sh "traject -c marc_to_solr/lib/traject_config.rb #{fixtures} #{url_arg}"
    else
      sh "traject -c marc_to_solr/lib/traject_config.rb #{fixtures} #{url_arg} #{commit}"
    end
  end
end

desc 'Index MARC_PATH files against SET_URL'
task :index_folder do
  solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
  Dir["#{ENV.fetch('MARC_PATH', nil)}/*.xml"].sort.each do |fixtures|
    sh "rake index SET_URL=#{solr_url} MARC=#{fixtures} NO_COMMIT=1; true"
  end
  solr = IndexFunctions.rsolr_connection(solr_url)
  solr.commit
end

desc "which chunks from BIB_DUMP didn't index against SET_URL?"
task :check do
  if ENV['BIB_DUMP']
    index_url = ENV.fetch('SET_URL', nil) || default_solr_url
    solr = IndexFunctions.rsolr_connection(index_url)
    `awk 'NR % 50000 == 0 {print} END {print}' #{ENV.fetch('BIB_DUMP', nil)}`.split("\n").each_with_index do |bib, i|
      puts i if solr.get('get', params: { id: "#{bib}" })['doc'].nil?
    end
  end
end

desc "which of the BIBS given didn't index against SET_URL?"
task :check_given do
  if ENV['BIBS']
    index_url = ENV.fetch('SET_URL', nil) || default_solr_url
    solr = IndexFunctions.rsolr_connection(index_url)
    `awk '{print}' #{ENV.fetch('BIBS', nil)}`.split("\n").each do |bib|
      puts bib if solr.get('get', params: { id: "#{bib}" })['doc'].nil?
    end
  end
end

desc 'which chunks from BIB_DUMP indexed against SET_URL?'
task :check_included do
  if ENV['BIB_DUMP']
    index_url = ENV.fetch('SET_URL', nil) || default_solr_url
    solr = IndexFunctions.rsolr_connection(index_url)
    `awk 'NR % 50000 == 0 {print} END {print}' #{ENV.fetch('BIB_DUMP', nil)}`.split("\n").each_with_index do |bib, i|
      puts i unless solr.get('get', params: { id: "#{bib}" })['doc'].nil?
    end
  end
end

desc 'Deletes given BIB from SET_URL'
task :delete_bib do
  solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
  solr = IndexFunctions.rsolr_connection(solr_url)
  if ENV['BIB']
    solr.delete_by_id(ENV.fetch('BIB', nil))
    solr.commit
  else
    puts 'Please provide a BIB argument (BIB=####)'
  end
end

namespace :liberate do
  desc 'Index latest full record dump against SET_URL'
  task full: :environment do
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    solr = IndexFunctions.rsolr_connection(solr_url)
    reindex = IndexManager.reindex!(solr_url:)
    if reindex
      puts 'INFO: Reindex started'
    else
      puts 'WARN: The reindex was not started (perhaps there is another reindex in progress.)'
    end
  end

  desc 'Index remaining incrementals against SET_URL'
  task incremental: :environment do
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    IndexManager.for(solr_url).index_remaining!
  end

  desc 'Index a single MARC XML file against SET_URL'
  task index_file: :environment do
    solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
    file_name = ENV.fetch('FILE', nil)
    debug = ENV.fetch('DEBUG', nil) == 'true'
    abort 'MARC XML file name must be indicated via FILE environment variable' unless file_name
    solr = IndexFunctions.rsolr_connection(solr_url)
    Alma::Indexer.new(solr_url:).index_file_debug(file_name)
    solr.commit
  end

  desc 'Logs the deleted and updated IDs in the MARC files associated with a Dump'
  task dump_log_ids: :environment do
    dump_id = ENV['DUMP_ID'].to_i
    abort 'DUMP_ID file name must be indicated via environment variable' unless dump_id > 0
    service = DumpLogIdsService.new
    service.process_dump(dump_id)
  end

  namespace :arks do
    desc 'Seed the ARK cache'
    task :seed_cache, [:figgy_dir_path] do |_t, args|
      figgy_dir_path = args[:figgy_dir_path] || Rails.root.join('tmp', 'figgy_ark_cache')
      figgy_lightly = Lightly.new(dir: figgy_dir_path, life: 0, hash: false)
      figgy_cache_adapter = CacheAdapter.new(service: figgy_lightly)

      logger = Logger.new(STDOUT)
      cache_manager = CacheManager.initialize(figgy_cache: figgy_cache_adapter, logger:)
      cache_manager.seed!
    end

    desc 'Clear the ARK cache'
    task :clear_cache, [:figgy_dir_path] do |_t, args|
      figgy_dir_path = args[:figgy_dir_path] || Rails.root.join('tmp', 'figgy_ark_cache')
      CacheManager.clear(dir: figgy_dir_path)
    end

    desc 'Clear, then seed, the ARK cache'
    task :clear_and_seed_cache, [:figgy_dir_path] do |_t, args|
      figgy_dir_path = ENV.fetch('FIGGY_ARK_CACHE_PATH', nil) || args[:figgy_dir_path] || Rails.root.join('tmp', 'figgy_ark_cache')
      Rake::Task['liberate:arks:clear_cache'].invoke(figgy_dir_path)
      Rake::Task['liberate:arks:seed_cache'].invoke(figgy_dir_path)
    end
  end
end

namespace :numismatics do
  namespace :index do
    desc 'Index all the complete, open numismatic coins from figgy'
    task full: :environment do
      solr_url = ENV.fetch('SET_URL', nil) || default_solr_url
      Index::NumismaticsJob.perform_async(solr_url)
    end
  end
end

namespace :augment do
  desc 'Recreates two out of three fixture files from CSV for AugmentTheSubject - LCSH_STANDALONE_X_FILE file must be hand created'
  task recreate_fixtures: :environment do
    subfield_a_output = AugmentTheSubject.parse_standalone_a
    required_subfields_output = AugmentTheSubject.parse_required_subfields

    File.write(AugmentTheSubject::LCSH_STANDALONE_A_FILE, subfield_a_output.to_json)
    File.write(AugmentTheSubject::LCSH_REQUIRED_SUBFIELDS, required_subfields_output.to_json)
  end
end
