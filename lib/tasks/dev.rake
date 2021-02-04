namespace :servers do
  task initialize: :environment do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
  end

  desc "Start the Apache Solr and PostgreSQL container services using Lando."
  task start: :environment do
    system("lando start")
    system("rake servers:initialize")
    LocationMapsGeneratorService.generate_from_templates
  end

  desc "Stop the Lando Apache Solr and PostgreSQL container services."
  task stop: :environment do
    system("lando stop")
  end
end

namespace :marc_liberation do
  desc "Populate holding location values from database."
  task process_locations: :environment do
    LocationMapsGeneratorService.generate
  end
end

namespace :server do
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
        puts solr_dir
        ["_rest_managed.json", "admin-extra.html", "elevate.xml",
         "mapping-ISOLatin1Accent.txt", "protwords.txt", "schema.xml",
         "scripts.conf", "solrconfig.xml", "spellings.txt", "stopwords.txt",
         "stopwords_en.txt", "synonyms.txt"].each do |file|
           response = Faraday.get url_for_file(file)
           if response.success?
             File.open(File.join(solr_dir, "conf", file), "wb") do |f|
               # byebug
               body = response.body
               if file == "solrconfig.xml"
                 body = "<!-- first line -->\n" + body
                 puts "fixed #{file} - source: #{url_for_file(file)}"
               end
               f.write(body)
             end
           end
         end
      end

      def url_for_file(file)
        "https://raw.githubusercontent.com/pulibrary/pul_solr/master/solr_configs/catalog-production/conf/#{file}"
      end
    end
  end
end
