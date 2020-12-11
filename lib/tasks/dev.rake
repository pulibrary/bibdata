namespace :server do
  desc "Configures and starts dependent servers"
  task initialize: :environment do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end

  desc "Start solr and postgres servers using lando."
  task start: :environment do
    system("lando start")
    system("rake server:initialize")
    system("rake server:initialize RAILS_ENV=test")
  end

  desc "Stop lando solr and postgres servers."
  task stop: :environment do
    system("lando stop")
  end

  namespace :solr do
    task start_solr_wrapper: :environment do
      SolrWrapper.wrap(port: 8983, verbose: true, managed: true, download_dir: 'tmp', version: '8.4.1') do |solr|
        solr.with_collection(name: 'marc-liberation-core-test', dir: 'solr/conf') do
          puts "Started SolrWrapper at https://127.0.0.1:8983, press Ctrl+C to close"
          loop { sleep }
        end
      end
    end
    namespace :configs do
      desc "Updates solr config files from github"
      task :update, [:solr_dir] => :environment do |_t, args|
        solr_dir = args[:solr_dir] || Rails.root.join("solr")

        ["_rest_managed.json", "admin-extra.html", "elevate.xml",
         "mapping-ISOLatin1Accent.txt", "protwords.txt", "schema.xml",
         "scripts.conf", "solrconfig.xml", "spellings.txt", "stopwords.txt",
         "stopwords_en.txt", "synonyms.txt"].each do |file|
           response = Faraday.get url_for_file(file)
           File.open(File.join(solr_dir, "conf", file), "wb") { |f| f.write(response.body) } if response.success?
         end
      end

      def url_for_file(file)
        "https://raw.githubusercontent.com/pulibrary/pul_solr/master/solr_configs/catalog-production/conf/#{file}"
      end
    end
  end
end
