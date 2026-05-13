task('spec').clear
desc 'Run rspec with required env variables'
task :spec do
  if Rails.env.development? || Rails.env.staging?
    ENV['TRAJECT_CONFIG'] = 'marc_to_solr/lib/traject_config.rb'
    sh 'rspec spec marc_to_solr/spec'
  end
end
