require 'csv'
module Hathi
  # Load all allow or deny rows from the given file into HathiAccess objects
  # with the given origin
  # expected header rows are
  # oclcl, local_id, item_type, access, rights
  class LoadOverlapFile
    attr_reader :input_location, :source
    def initialize(input_location:, source:)
      @input_location = input_location
      @source = source
    end

    def load
      CSV.foreach(input_location, { headers: true, col_sep: "\t" }) do |row|
        next unless row["access"]
        HathiAccess.create!(
          oclc_number: row["oclc"],
          bibid: row["local_id"],
          status: row["access"].upcase,
          origin: source
        )
      end
    end
  end
end
