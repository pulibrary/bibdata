namespace :alma do
  desc "Set up Alma keys"
  task :setup_keys do
    ftp_credentials = build_ftp_credentials_hash
    File.open(".env", "w") do |f|
      f.puts "ALMA_BIBS_READ_ONLY=#{read_key}"
      f.puts "FTP_USERNAME=#{ftp_credentials['Username']}"
      f.puts "FTP_PASSWORD=#{ftp_credentials['Password']}"
    end
    puts "Generated .env file"
  end
end

def read_key
  keys = `lpass show Shared-ITIMS-Passwords/alma/AlmaKeys --notes`
  keys = build_hash(keys)
  keys["bibs_read_only"].split(" ").first
end

def build_ftp_credentials_hash
  credentials = `lpass show Shared-ITIMS-Passwords/Enterprise-and-User-Services/alma-SFTP-credentials`
  build_hash(credentials)
end

def build_hash(keys)
  keys = keys.split("\n").map do |key|
    key.split(":", 2).map(&:strip)
  end.to_h
end
