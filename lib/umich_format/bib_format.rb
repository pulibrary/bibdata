# given a record, find the bib_format code
require 'lib/umich_format.rb'

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
      if (record['502']['a'].include? "(Senior)--Princeton University") || (record['502']['a'].include? "Thesis (Senior)-Princeton University")
        @code = "ST"
      else
        @code = "TH"
      end
    else
      @code = self.determine_bib_code(type, lev)
    end
  end

  def determine_bib_code(type, lev)
    return "BK" if bibformat_bk(type, lev)
    return "AJ" if bibformat_jn(type, lev)    
    return "CF" if bibformat_cf(type, lev)
    return "VM" if bibformat_vm(type, lev)
    return "VP" if bibformat_vp(type, lev)    
    return "MS" if bibformat_mu(type, lev)
    return "AU" if bibformat_au(type, lev)
    return "MP" if bibformat_mp(type, lev)
    return "MW" if bibformat_mw(type, lev)
    return "MX" if bibformat_mx(type, lev)



    # No match
    return 'XX'

  end

  def bibformat_bk(type, lev)
    (type == 'a') && %w[a b c d i m].include?(lev)
  end

  def bibformat_jn(type, lev)
    (type == 'a') && (lev == 's')
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
    (type == 'c') #&& %w[a b c d m s].include?(lev)
  end

  def bibformat_mp(type, lev)
    (type = 'e')
  end

  def bibformat_mw(type, lev)
    %w[d f t].include?(type)
  end

  def bibformat_mx(type, lev)
    (type == 'p')
  end
end
