require 'lib/translation_map'
require 'lib/umich_format/bib_format'
require 'lib/umich_format/bib_types'

# Encapsulates logic that uses University of Michigan University Library
# rules to determine both bib format (book, serial, visual
# material, etc.) and type, a more expansive list including both format
# (blu-ray, microform) and more semantic categories (bibliography,
# conference)

class UMichFormat
  # @!attribute [r] record
  #   The record passed into the constructor
  # @!attribute [r] bib_format
  #   The bib format code as computed from the passed record
  # @!attribute [r] types
  #   A (possibly empty) array of type codes as computed from record data
  attr_reader :bib_format, :record, :types

  # Construct a Formats object from the given record, calcuclating
  # the bib_format and types
  #
  # @param [MARC::Record] record
  def initialize(marc_record)
    @record     = marc_record
    @bib_format = BibFormat.new(record).code
    @types      = BibTypes.new(@bib_format, record).codes
  end

  def format_and_types
    types = @types.dup
    types.unshift bib_format
    types
  end




end

