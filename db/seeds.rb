seeder = DataSeeder.new
seeder.generate_dump_types
seeder.generate_dump_file_types

if Event.count < 10 && Rails.env.development?
  10.times do |i|
    Event.find_or_create_by(start: "200#{i}-10-10", finish: "200#{i}-10-11", success: true)
  end
end
