json.type @dump.dump_type.downcase
json.generated_date @dump.generated_date
json.files do
  DumpFile.dump_file_types.each do |dft|
    json.set! dft, @dump.dump_files.where(dump_file_type: dft).each do |df|
      json.dump_file dump_file_url(df)
      json.md5 df.md5
    end
  end
end
json.ids do
  json.delete_ids @dump.delete_ids
  json.update_ids @dump.update_ids
end
