FactoryBot.define do
  factory :event do
    start { Time.now }
    finish { Time.now + 3600 }
    error { nil }
    success { true }
    created_at { finish }
    updated_at { finish }
  end

  factory :full_dump_file_type, class: "DumpFileType" do
    constant { "BIB_RECORDS" }
    label { "All Bib Records" }
  end

  factory :incremental_dump_file_type, class: "DumpFileType" do
    constant { 'UPDATED_RECORDS' }
    label { 'Updated Records' }
  end

  factory :recap_incremental_dump_file_type, class: "DumpFileType" do
    constant { 'RECAP_RECORDS' }
    label { 'Recap Records' }
  end

  factory :partner_recap_daily_dump_file_type, class: "DumpFileType" do
    constant { 'RECAP_RECORDS' }
    label { 'Updated ReCAP Records' }
  end

  factory :partner_recap_full_dump_file_type, class: "DumpFileType" do
    constant { 'Full ReCAP Records' }
    label { 'RECAP_RECORDS_FULL' }
  end

  factory :dump_file do
    association :dump_file_type, factory: :full_dump_file_type
  end

  factory :incremental_dump_file, class: "DumpFile" do
    association :dump_file_type, factory: :incremental_dump_file_type
  end

  factory :recap_incremental_dump_file, class: "DumpFile" do
    association :dump_file_type, factory: :recap_incremental_dump_file_type
  end

  factory :partner_recap_daily_dump_file, class: "DumpFile" do
    association :dump_file_type, factory: :partner_recap_daily_dump_file_type
  end

  factory :partner_recap_full_dump_file, class: "DumpFile" do
    association :dump_file_type, factory: :partner_recap_full_dump_file_type
  end

  factory :empty_dump, class: "Dump" do
    dump_type_id { 1 }
    association :event
  end

  factory :empty_incremental_dump, class: "Dump" do
    dump_type_id { 2 }
    association :event
  end

  factory :empty_partner_recap_incremental_dump, class: "Dump" do
    dump_type_id { 4 }
    association :event
  end

  factory :empty_partner_full_dump, class: "Dump" do
    dump_type_id { 5 }
    association :event
  end

  factory :empty_partner_recap_dump, class: "Dump" do
    dump_type_id { 4 }
    association :event
  end

  factory :full_dump, class: "Dump" do
    generated_date { Time.new(2021, 7, 13, 11, 0, 0, "+00:00") }
    delete_ids { [] }
    update_ids { [] }
    dump_type_id { 1 }
    dump_files do
      [
        association(:dump_file, path: 'spec/fixtures/files/alma/full_dump/1.xml.tar.gz'),
        association(:dump_file, path: 'spec/fixtures/files/alma/full_dump/2.xml.tar.gz')
      ]
    end
  end

  factory :incremental_dump, class: "Dump" do
    delete_ids { [] }
    update_ids { [] }
    dump_type_id { 2 }
    dump_files do
      [
        association(:incremental_dump_file, path: 'spec/fixtures/files/alma/incremental_dump/1.tar.gz'),
        association(:incremental_dump_file, path: 'spec/fixtures/files/alma/incremental_dump/2.tar.gz')
      ]
    end
  end

  factory :partner_recap_daily_dump, class: "Dump" do
    dump_type_id { 4 }
    delete_ids { [] }
    update_ids { [] }
    dump_files do
      [
        association(:partner_recap_daily_dump_file, path: 'spec/fixtures/scsb_updates/scsb_update_20240110_192400_1.xml.gz'),
        association(:partner_recap_daily_dump_file, path: 'spec/fixtures/scsb_updates/scsb_update_20240108_183400_1.xml.gz')
      ]
    end
  end

  factory :partner_recap_full_dump, class: "Dump" do
    dump_type_id { 5 }
    delete_ids { [] }
    update_ids { [] }
    dump_files do
      [
        association(:partner_recap_full_dump_file, path: 'spec/fixtures/scsb_updates/scsbfull_nypl_20240101_150000_1.xml.gz')
      ]
    end
  end

  factory :full_dump_event, class: "Event" do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :full_dump
  end

  factory :incremental_dump_event, class: "Event" do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :incremental_dump
  end

  factory :partner_recap_daily_event, class: "Event" do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :partner_recap_daily_dump
  end

  factory :partner_recap_full_event, class: "Event" do
    start { Time.now - 3600 }
    finish { Time.now - 100 }
    error { nil }
    success { true }
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :partner_recap_full_dump
  end
end
