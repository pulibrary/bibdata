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
    @code = self.determine_bib_code(type, lev)
  end

  def determine_bib_code(type, lev)
    return 'BK' if bibformat_bk(type, lev)
    return "CF" if bibformat_cf(type, lev)
    return "VM" if bibformat_vm(type, lev)
    return "MU" if bibformat_mu(type, lev)
    return "MP" if bibformat_mp(type, lev)
    return "SE" if bibformat_se(type, lev)
    return "MX" if bibformat_mx(type, lev)

    # Extra check for serial
    return "SE" if lev == 's'

    # No match
    return 'XX'

  end

  def bibformat_bk(type, lev)
    %w[a t].include?(type) && %w[a c d m].include?(lev)
  end

  def bibformat_cf(type, lev)
    (type == 'm') && %w[a b c d m s].include?(lev)
  end

  def bibformat_vm(type, lev)
    %w[g k o r].include?(type) && %w[a b c d m s].include?(lev)
  end

  def bibformat_mu(type, lev)
    %w[c d i j].include?(type) && %w[a b c d m s].include?(lev)
  end

  def bibformat_mp(type, lev)
    %w[e f].include?(type) && %w[a b c d m s].include?(lev)
  end

  def bibformat_se(type, lev)
    (type == 'a') && %w[b s i].include?(lev)
  end

  def bibformat_mx(type, lev)
    %w[b p].include?(type) && %w[a b c d m s].include?(lev)
  end
end
