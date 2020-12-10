namespace :server do
  namespace :solr do
    namespace :configs do
      desc "Updates solr config files from github"
      task :update, [:solr_dir] => :environment do |_t, args|
        solr_dir = args[:solr_dir] || Rails.root.join("solr")

        ["_rest_managed.json", "admin-extra.html", "elevate.xml",
         "mapping-ISOLatin1Accent.txt", "protwords.txt", "schema.xml",
         "scripts.conf", "solrconfig.xml", "spellings.txt", "stopwords.txt",
         "stopwords_en.txt", "synonyms.txt"].each do |file|
           response = Faraday.get url_for_file(file)
           File.open(File.join(solr_dir, "conf", file), "wb") { |f| f.write(response.body) }
         end
      end

      def url_for_file(file)
        "https://raw.githubusercontent.com/pulibrary/pul_solr/master/solr_configs/catalog-production/#{file}"
      end
    end
  end
end
