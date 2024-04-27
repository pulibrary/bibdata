require 'rails_helper'
require 'fileutils'

RSpec.describe 'Devise restricts features for unauthenticated users', type: :system, js: true do
  before(:all) do
    dump_test_bib_ids('./spec/fixtures/sample_bib_ids.txt')
  end

  after(:all) do
    Event.destroy_all
    Library.destroy_all
    HoldingLocation.destroy_all
    DeliveryLocation.destroy_all
  end

  unless ENV['CI']
    scenario 'Anyone can retrieve an event dump' do
      event = Event.last
      visit "/events/#{event.id}"
      click_link "Dump"
    end

    scenario "anyone can retrieve JSON feeds for events" do
      visit "/events.json"
    end

    scenario "unauthenticated users can not delete events" do
      visit "/events"
      expect(page).not_to have_link "Delete"
    end

    scenario "only authenticated users can delete events" do
      sign_in FactoryBot.create(:admin), scope: :user
      visit "/events"
      expect(page).to have_link "Delete"
    end
  end

  ["libraries", "holding_locations", "delivery_locations"].each_with_index do |data_type, _i|
    scenario "anyone can retrieve JSON feeds for #{data_type}" do
      visit "/locations/#{data_type}.json"
    end
  end

  def dump_test_bib_ids(bibs)
    dump = nil
    Event.record do |event|
      dump = Dump.create(dump_type: :bib_ids)
      dump.event = event
      dump_file = DumpFile.create(dump:, dump_file_type: :bib_ids)
      FileUtils.cp bibs, dump_file.path
      dump_file.save
      dump_file.zip
      dump.dump_files << dump_file
      dump.save
    end
    dump
  end
end
