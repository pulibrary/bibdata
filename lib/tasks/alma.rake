namespace :alma do
  desc 'Set up Alma keys'
  task :setup_keys do
    sftp_credentials = build_sftp_credentials_hash
    File.open('.env', 'w') do |f|
      f.puts "ALMA_READ_ONLY_APIKEY=#{read_key}"
      f.puts "ALMA_REGION=#{region_key}"
      f.puts "SFTP_USERNAME=#{sftp_credentials['Username']}"
      f.puts "SFTP_PASSWORD=#{sftp_credentials['Password']}"
      f.puts "SFTP_HOST=#{sftp_credentials['URL'].split('/').last}"
    end
    puts 'Generated .env file'
  end
end

def read_key
  `lpass show Shared-ITIMS-Passwords/alma/api-key-production-read-only --notes`
end

def region_key
  `lpass show Shared-ITIMS-Passwords/alma/alma_region --notes`
end

def build_sftp_credentials_hash
  credentials = `lpass show Shared-ITIMS-Passwords/Enterprise-and-User-Services/alma-SFTP-credentials`
  build_hash(credentials)
end

def build_hash(keys)
  keys = keys.split("\n").map do |key|
    key.split(':', 2).map(&:strip)
  end.to_h
end
