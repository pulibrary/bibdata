# given a record, find the bib_format code
require './lib/format.rb'

class BibFormat

  attr_reader :code

  # Determine the bib format code
  #
  # @param [MARC::Record] record The record to test

  def initialize(record)
    ldr = record.leader
    type = ldr[6]
    lev  = ldr[7]
    # assuming all 502s have an a subfield
    if record['502']
      if record['502']['a']
        if (record['502']['a'].include? "(Senior)--Princeton University") || (record['502']['a'].include? "Thesis (Senior)-Princeton University")
          @code = ["ST"]
        else
          @code = ["TH"]
        end
      end
    else
      @code = self.determine_bib_code(type, lev)
    end
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

    format << 'XX' if format.empty? # unknown if no match
    format
  end

  def bibformat_bk(type, lev)
    (type == 't') or ((type == 'a') and %w[a b c d i m].include?(lev))
  end

  def bibformat_jn(type, lev)
    (type == 'a') and (lev == 's')
  end  

  def bibformat_cf(type, lev)
    (type == 'm') 
  end

  def bibformat_au(type, lev)
    %w[i j].include?(type)
  end  

  def bibformat_vm(type, lev)
    %w[k o r].include?(type) 
  end

  def bibformat_vp(type, lev)
    (type == 'g') 
  end

  def bibformat_mu(type, lev)
    %w[c d].include?(type)
  end

  def bibformat_mp(type, lev)
    %w[e f].include?(type)
  end

  def bibformat_mw(type, lev)
    %w[d f p t].include?(type)
  end

end
