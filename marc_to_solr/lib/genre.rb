# This class is responsible for listing the
# genres present in a given MARC record
class Genre
  SUBJECT_GENRE_VOCABULARIES = ['sk', 'aat', 'lcgft', 'rbbin', 'rbgenr', 'rbmscv',
                                'rbpap', 'rbpri', 'rbprov', 'rbpub', 'rbtyp', 'homoit'].freeze

  def initialize(record)
    @record = record
  end

  # 600/610/650/651 $v, $x filtered
  # 655 $a, $v, $x filtered
  def to_a
    @as_array ||= (
      genres_from_subfield_x + genres_from_subject_vocabularies + genres_from_subfield_v
    ).uniq
  end

  private

    attr_reader :record

    def genres_from_subfield_x
      Traject::MarcExtractor.cached('600|*0|x:610|*0|x:611|*0|x:630|*0|x:650|*0|x:651|*0|x:655|*0|x').collect_matching_lines(record) do |field, spec, extractor|
        genre = extractor.collect_subfields(field, spec).first
        next if genre.nil?
        genre = Traject::Macros::Marc21.trim_punctuation(genre)
        genre if likely_genre_term(genre)
      end
    end

    def genres_from_subject_vocabularies
      Traject::MarcExtractor.cached('650|*7|v:655|*7|a:655|*7|v').collect_matching_lines(record) do |field, spec, extractor|
        should_include = field.subfields.any? do |s_field|
          # only include heading if it is part of the vocabulary
          SUBJECT_GENRE_VOCABULARIES.include?(s_field.value) if s_field.code == '2'
        end
        genre = extractor.collect_subfields(field, spec).first
        next if genre.nil?
        genre = Traject::Macros::Marc21.trim_punctuation(genre)
        if genre.match?(/^\s+$/)
          logger.error "#{record['001']} - Blank genre field"
          next
        elsif should_include
          genre
        end
      end
    end

    def genres_from_subfield_v
      Traject::MarcExtractor.cached('600|*0|v:610|*0|v:611|*0|v:630|*0|v:650|*0|v:651|*0|v:655|*0|a:655|*0|v').collect_matching_lines(record) do |field, spec, extractor|
        genre = extractor.collect_subfields(field, spec).first
        next if genre.nil?
        genre = Traject::Macros::Marc21.trim_punctuation(genre)
        if genre.match?(/^\s+$/)
          logger.error "#{record['001']} - Blank genre field"
          next
        end
        genre
      end
    end

    def likely_genre_term term
      genre_terms.include?(term) || genre_starting_terms.any? { |potential| term.start_with? potential }
    end

    def genre_terms
      [
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
      ]
    end

    def genre_starting_terms
      [
        'Census',
        'Maps',
        'Methods',
        'Parts',
        'Personal narratives',
        'Scores and parts',
        'Study and teaching',
        'Translations into '
      ]
    end
end
