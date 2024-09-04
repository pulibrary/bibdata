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
    @code = []
    @code << self.determine_bib_code(type, lev)
    @code = @code.flatten
    # Removed per @tampakis recommendation to keep items with an unknown format
    # value out of the format facet
    # @code << 'XX' if @code.empty?
  end

  def determine_bib_code(type, lev)
    format = []
    format << "AJ" if bibformat_jn(type, lev) # journal
    format << "CF" if bibformat_cf(type, lev) # data file
    format << "VM" if bibformat_vm(type, lev) # visual material
    format << "VP" if bibformat_vp(type, lev) # video
    format << "MS" if bibformat_mu(type, lev) # musical score
    format << "AU" if bibformat_au(type, lev) # audio
    format << "MP" if bibformat_mp(type, lev) # map
    format << "MW" if bibformat_mw(type, lev) # manuscript
    format << "BK" if bibformat_bk(type, lev) # book
    format
  end

  def bibformat_bk(type, lev)
    (type == 't') || ((type == 'a') && %w[a b c d i m].include?(lev))
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
end
