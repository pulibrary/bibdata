namespace :alma do
  desc "Set up Alma keys"
  task :setup_keys do
    keys = `lpass show Shared-ITIMS-Passwords/alma/AlmaKeys --notes`
    keys = keys.split("\n").map do |key|
      key.split(":").map(&:strip)
    end.to_h
    read_key = keys["bibs_read_only"].split(" ").first
    File.open(".env", "w") do |f|
      f.puts "ALMA_BIBS_READ_ONLY=#{read_key}"
    end
    puts "Generated .env file"
  end
end
