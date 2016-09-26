class LanguageService
  def self.loc_to_iso(loc)
    if codes = ISO_639.find(loc)
      term = codes.alpha3_terminologic # blank when iso and loc are the same
      iso = term unless term.empty?
      iso ||= codes.alpha3
    end
  end
end
