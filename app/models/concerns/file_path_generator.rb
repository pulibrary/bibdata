module FilePathGenerator
  def generate_fp
    File.join(MARC_LIBERATION_CONFIG['data_dir'], "#{Time.now.to_i.to_s}")
  end
end
