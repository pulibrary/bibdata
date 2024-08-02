if Event.count < 9 && Rails.env.development?
  9.times do |i|
    Event.find_or_create_by(start: "200#{i}-10-10", finish: "200#{i}-10-11", success: true)
  end
end

if Dump.count < 9 && Rails.env.development?
  Event.all.each do |event|
    event.dump = Dump.create!(dump_type: :changed_records, event:)
    event.save
  end
end
