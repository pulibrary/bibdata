task("spec").clear
desc "Run rspec with required env variables"
task :spec do
  if Rails.env.development? || Rails.env.staging?
    ENV['FIGGY_ARK_CACHE_PATH'] = 'spec/fixtures/marc_to_solr/figgy_ark_cache'
    ENV['TRAJECT_CONFIG'] = 'marc_to_solr/lib/traject_config.rb'
    ENV['HATHI_OUTPUT_DIR'] = 'spec/fixtures/marc_to_solr/'
    sh "rspec spec marc_to_solr/spec"
  end
end
