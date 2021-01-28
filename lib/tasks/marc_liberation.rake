namespace :marc_liberation do
  namespace :server do
    task initialize: :environment do
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
    end

    desc "Start the Apache Solr and PostgreSQL container services using Lando."
    task start: :environment do
      system("lando start")
      system("rake marc_liberation:server:initialize")
      Rake::Task["marc_liberation:process_locations"].invoke unless LocationProcessorService.processed?
    end

    desc "Stop the Lando Apache Solr and PostgreSQL container services."
    task stop: :environment do
      system("lando stop")
    end
  end

  desc "Populate the holding locations values."
  task process_locations: :environment do
    LocationMapsGeneratorService.generate
  end
end
