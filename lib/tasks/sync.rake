namespace :marc_liberation do
  desc 'Adds updated partner recap records'
  task partner_update: :environment do
    Dump.partner_update
  end
end
