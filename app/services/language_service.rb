class LanguageService
  def self.label_to_iso(language)
    LANGUAGES.select { |lang| lang['label'].split(';').include? language }.first['iso']
  end

  def self.loc_to_iso(loc)
    LANGUAGES.select { |lang| lang['loc'] == loc }.first['iso']
  end
end
