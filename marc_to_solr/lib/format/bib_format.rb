# given a record, find the bib_format code
require_relative '../format.rb'

# This class is responsible for assigning one or more 2-letter
# codes that represent the format of a title.  The 2-letter
# codes can be found in the Format translation map.
class BibFormat
  attr_reader :code

  # Determine the bib format code
  #
  # @param [MARC::Record] record The record to test

  def initialize(record)
    @record = record
    @code = []
    @code << self.determine_bib_code
    @code << 'WM' if microform?
    @code = @code.flatten
  end

  def determine_bib_code
    format = []
    format << "AJ" if bibformat_jn # journal
    format << "CF" if bibformat_cf # data file
    format << "VM" if bibformat_vm # visual material
    format << "VP" if bibformat_vp # video
    format << "MS" if bibformat_mu # musical score
    format << "AU" if bibformat_au # audio
    format << "MP" if bibformat_mp # map
    format << "MW" if bibformat_mw # manuscript
    format << "BK" if bibformat_bk # book
    format << "DB" if bibformat_db # databases
    format << "XA" if bibformat_xa # archival item
    format
  end

  def bibformat_bk
    ((type == 't') && !check_pulfa) || ((type == 'a') && %w[a b c d m].include?(lev))
  end

  def bibformat_db
    (type == 'a') && (lev == 'i')
  end

  def bibformat_jn
    (type == 'a') && (lev == 's')
  end

  def bibformat_cf
    (type == 'm')
  end

  def bibformat_au
    %w[i j].include?(type)
  end

  def bibformat_vm
    %w[k o r].include?(type)
  end

  def bibformat_vp
    (type == 'g')
  end

  def bibformat_mu
    %w[c d].include?(type)
  end

  def bibformat_mp
    %w[e f].include?(type)
  end

  def bibformat_mw
    %w[d f p t].include?(type)
  end

  def bibformat_xa
    (type == 't') && (lev == 'm') && check_pulfa && archival?
  end

  private

    attr_reader :record

    def microform?
      record.fields('007').any? { |field| field.value&.start_with? 'h' }
    end

    def ldr
      @ldr ||= record.leader
    end

    def type
      @type ||= ldr[6]
    end

    def lev
      @lev ||= ldr[7]
    end

    def check_pulfa
      @check_pulfa ||= record['035'] && record['035']['a'] && record['035']['a'].start_with?('(PULFA)')
    end

    def archival?
      @archival ||= begin
        cataloging_sources = record.fields('040')
        return true if cataloging_sources.empty?

        cataloging_sources.any? { |field| field_uses_archival_standard?(field) }
      end
    end

    def field_uses_archival_standard?(field)
      field.subfields.any? { |subfield| subfield.code == 'e' && archival_standard?(subfield.value) } ||
        field.subfields.none? { |subfield| subfield.code == 'e' && !archival_standard?(subfield.value) }
    end

    def archival_standard?(code)
      %w[dacs appm].include? code
    end
end
