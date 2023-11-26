seeder = DataSeeder.new
seeder.generate_dump_types
seeder.generate_dump_file_types

10.times do |i|
  Event.find_or_create_by(id: i+1, start: "200#{i}-10-10", finish: "200#{i}-10-11", success: true)
end
