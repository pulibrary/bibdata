FactoryBot.define do
  factory :index_manager do
    solr_collection { "MyString" }
    dump_in_progress { nil }
    last_dump_completed { nil }
  end
end
