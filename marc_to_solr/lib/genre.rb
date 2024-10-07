# This class is responsible for listing the
# genres present in a given MARC record
class Genre
  GENRES = [
    'Bibliography',
    'Biography',
    'Catalogs',
    'Catalogues raisonnes',
    'Commentaries',
    'Congresses',
    'Diaries',
    'Dictionaries',
    'Drama',
    'Encyclopedias',
    'Exhibitions',
    'Fiction',
    'Guidebooks',
    'In art',
    'Indexes',
    'Librettos',
    'Manuscripts',
    'Newspapers',
    'Periodicals',
    'Pictorial works',
    'Poetry',
    'Portraits',
    'Scores',
    'Songs and music',
    'Sources',
    'Statistics',
    'Texts',
    'Translations'
  ].freeze

  GENRE_STARTS_WITH = [
    'Census',
    'Maps',
    'Methods',
    'Parts',
    'Personal narratives',
    'Scores and parts',
    'Study and teaching',
    'Translations into '
  ].freeze

  SUBJECT_GENRE_VOCABULARIES = ['sk', 'aat', 'lcgft', 'rbbin', 'rbgenr', 'rbmscv',
                                'rbpap', 'rbpri', 'rbprov', 'rbpub', 'rbtyp', 'homoit'].freeze

  def initialize(record)
    @record = record
  end

  # 600/610/650/651 $v, $x filtered
  # 655 $a, $v, $x filtered
  def to_a
    genres = []
    Traject::MarcExtractor.cached('600|*0|x:610|*0|x:611|*0|x:630|*0|x:650|*0|x:651|*0|x:655|*0|x').collect_matching_lines(record) do |field, spec, extractor|
      genre = extractor.collect_subfields(field, spec).first
      unless genre.nil?
        genre = Traject::Macros::Marc21.trim_punctuation(genre)
        genres << genre if GENRES.include?(genre) || GENRE_STARTS_WITH.any? { |g| genre[g] }
      end
    end
    Traject::MarcExtractor.cached('650|*7|v:655|*7|a:655|*7|v').collect_matching_lines(record) do |field, spec, extractor|
      should_include = false
      field.subfields.each do |s_field|
        # only include heading if it is part of the vocabulary
        should_include = SUBJECT_GENRE_VOCABULARIES.include?(s_field.value) if s_field.code == '2'
      end
      genre = extractor.collect_subfields(field, spec).first
      unless genre.nil?
        genre = Traject::Macros::Marc21.trim_punctuation(genre)
        if genre.match?(/^\s+$/)
          logger.error "#{record['001']} - Blank genre field"
        elsif should_include
          genres << genre
        end
      end
    end
    Traject::MarcExtractor.cached('600|*0|v:610|*0|v:611|*0|v:630|*0|v:650|*0|v:651|*0|v:655|*0|a:655|*0|v').collect_matching_lines(record) do |field, spec, extractor|
      genre = extractor.collect_subfields(field, spec).first
      unless genre.nil?
        genre = Traject::Macros::Marc21.trim_punctuation(genre)
        if genre.match?(/^\s+$/)
          logger.error "#{record['001']} - Blank genre field"
        else
          genres << genre
        end
      end
    end
    genres.uniq
  end

  private

    attr_reader :record
end
