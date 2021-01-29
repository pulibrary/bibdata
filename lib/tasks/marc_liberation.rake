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
      LocationMapsGeneratorService.generate_from_templates
    end

    desc "Stop the Lando Apache Solr and PostgreSQL container services."
    task stop: :environment do
      system("lando stop")
    end
  end

  desc "Populate holding location values from database."
  task process_locations: :environment do
    LocationMapsGeneratorService.generate
  end
end
