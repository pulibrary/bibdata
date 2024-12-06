# given a record, find the bib_format code
require_relative '../format.rb'

class BibFormat
  attr_reader :code

  # Determine the bib format code
  #
  # @param [MARC::Record] record The record to test

  def initialize(record)
    ldr = record.leader
    type = ldr[6]
    lev  = ldr[7]
    check_pulfa = record['035'] && record['035']['a'].start_with?('(PULFA)')
    check_dacs = record['040'] && record['040']['e'] == 'dacs'
    @code = []
    @code << self.determine_bib_code(type, lev, check_pulfa, check_dacs)
    @code << 'WM' if microform? record
    @code = @code.flatten
    # Removed per @tampakis recommendation to keep items with an unknown format
    # value out of the format facet
    # @code << 'XX' if @code.empty?
  end

  def determine_bib_code(type, lev, check_pulfa, check_dacs)
    format = []
    format << "AJ" if bibformat_jn(type, lev) # journal
    format << "CF" if bibformat_cf(type, lev) # data file
    format << "VM" if bibformat_vm(type, lev) # visual material
    format << "VP" if bibformat_vp(type, lev) # video
    format << "MS" if bibformat_mu(type, lev) # musical score
    format << "AU" if bibformat_au(type, lev) # audio
    format << "MP" if bibformat_mp(type, lev) # map
    format << "MW" if bibformat_mw(type, lev) # manuscript
    format << "BK" if bibformat_bk(type, lev, check_pulfa) # book
    format << "DB" if bibformat_db(type, lev) # databases
    format << "XA" if bibformat_xa(type, lev, check_pulfa, check_dacs) # archival item
    format
  end

  def bibformat_bk(type, lev, check_pulfa)
    ((type == 't') && !check_pulfa) || ((type == 'a') && %w[a b c d m].include?(lev))
  end

  def bibformat_db(type, lev)
    (type == 'a') && (lev == 'i')
  end

  def bibformat_jn(type, lev)
    (type == 'a') && (lev == 's')
  end

  def bibformat_cf(type, _lev)
    (type == 'm')
  end

  def bibformat_au(type, _lev)
    %w[i j].include?(type)
  end

  def bibformat_vm(type, _lev)
    %w[k o r].include?(type)
  end

  def bibformat_vp(type, _lev)
    (type == 'g')
  end

  def bibformat_mu(type, _lev)
    %w[c d].include?(type)
  end

  def bibformat_mp(type, _lev)
    %w[e f].include?(type)
  end

  def bibformat_mw(type, _lev)
    %w[d f p t].include?(type)
  end

  def bibformat_xa(type, lev, check_pulfa, check_dacs)
    (type == 't') && (lev == 'm') && check_pulfa && check_dacs
  end

  private

    def microform?(record)
      record.fields('007').any? { |field| field.value&.start_with? 'h' }
    end
end
