FactoryBot.define do
  factory :event do
    start { Time.now }
    finish { Time.now + 3600 }
    error { nil }
    success { true }
    created_at { finish }
    updated_at { finish }
  end

  factory :dump_file do
    dump_file_type { :bib_records }
  end

  factory :incremental_dump_file, class: 'DumpFile' do
    dump_file_type { :updated_records }
  end

  factory :partner_recap_daily_dump_file, class: 'DumpFile' do
    dump_file_type { :recap_records }
  end

  factory :partner_recap_full_dump_file, class: 'DumpFile' do
    dump_file_type { :recap_records_full }
  end

  factory :empty_dump, class: 'Dump' do
    dump_type { :full_dump }
    association :event
  end

  factory :empty_incremental_dump, class: 'Dump' do
    dump_type { :changed_records }
    association :event
  end

  factory :empty_partner_recap_incremental_dump, class: 'Dump' do
    dump_type { :partner_recap }
    association :event
  end

  factory :empty_partner_full_dump, class: 'Dump' do
    dump_type { :partner_recap_full }
    association :event
  end

  factory :empty_partner_recap_dump, class: 'Dump' do
    dump_type { :partner_recap }
    association :event
  end

  factory :full_dump, class: 'Dump' do
    generated_date { Time.new(2021, 7, 13, 11, 0, 0, '+00:00') }
    delete_ids { [] }
    update_ids { [] }
    dump_type { :full_dump }
    dump_files do
      [
        association(:dump_file, path: 'spec/fixtures/files/alma/full_dump/1.xml.tar.gz'),
        association(:dump_file, path: 'spec/fixtures/files/alma/full_dump/2.xml.tar.gz')
      ]
    end
    event_id { 1 }
  end

  factory :incremental_dump, class: 'Dump' do
    delete_ids { [] }
    update_ids { [] }
    dump_type { :changed_records }
    dump_files do
      [
        association(:incremental_dump_file, path: 'spec/fixtures/files/alma/incremental_dump/1.tar.gz'),
        association(:incremental_dump_file, path: 'spec/fixtures/files/alma/incremental_dump/2.tar.gz')
      ]
    end
    event_id { 1 }
  end

  factory :partner_recap_daily_dump, class: 'Dump' do
    dump_type { :partner_recap }
    delete_ids { [] }
    update_ids { [] }
    dump_files do
      [
        association(:partner_recap_daily_dump_file, path: 'spec/fixtures/scsb_updates/scsb_update_20240110_192400_1.xml.gz'),
        association(:partner_recap_daily_dump_file, path: 'spec/fixtures/scsb_updates/scsb_update_20240108_183400_1.xml.gz')
      ]
    end
    event_id { 1 }
  end

  factory :partner_recap_full_dump, class: 'Dump' do
    dump_type { :partner_recap_full }
    delete_ids { [] }
    update_ids { [] }
    dump_files do
      [
        association(:partner_recap_full_dump_file, path: 'spec/fixtures/scsb_updates/scsbfull_nypl_20240101_150000_1.xml.gz')
      ]
    end
    event_id { 1 }
  end

  factory :full_dump_event, class: 'Event' do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    alma_job_status { 'COMPLETED_SUCCESS' }
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :full_dump
  end

  factory :incremental_dump_event, class: 'Event' do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    alma_job_status { 'COMPLETED_SUCCESS' }
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :incremental_dump
  end

  factory :partner_recap_daily_event, class: 'Event' do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    alma_job_status {}
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :partner_recap_daily_dump
  end

  factory :partner_recap_full_event, class: 'Event' do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    alma_job_status {}
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :partner_recap_full_dump
  end
end
