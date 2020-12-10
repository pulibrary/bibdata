FactoryBot.define do
  factory :event do
    start Time.now
    finish Time.now + 3600
    error nil
    success true
    created_at { finish }
    updated_at { finish }
  end
  factory :full_dump_type, class: "DumpType" do
    constant "BIB_RECORDS"
    label "All Bib Records"
  end
  factory :dump_file do
  end
  factory :full_dump, class: "Dump" do
    association :dump_type, factory: :full_dump_type
    delete_ids []
    update_ids []
    dump_files do
      [
        association(:dump_file, path: 'spec/fixtures/files/alma/full_dump/1.xml.gz'),
        association(:dump_file, path: 'spec/fixtures/files/alma/full_dump/2.xml.gz')
      ]
    end
  end
  factory :full_dump_event, class: "Event" do
    start Time.now - 3600
    finish Time.now - 100
    error nil
    success true
    created_at { finish }
    updated_at { finish }
    association :dump, factory: :full_dump
  end
end
