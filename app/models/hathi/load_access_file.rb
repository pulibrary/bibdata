require 'csv'
module Hathi
  # Load all allow or deny rows from the given file into HathiAccess objects
  # with the given origin
  # expected header rows are
  # oclcl, local_id, item_type, access, rights
  class LoadAccessFile
    attr_reader :input_location, :origin
    def initialize(input_location:, origin:)
      @input_location = input_location
      @origin = origin
    end

    def load
      CSV.foreach(input_location, { headers: true, col_sep: "\t" }) do |row|
        next unless row["access"]
        HathiAccess.find_or_create_by!(
          oclc_number: row["oclc"],
          bibid: row["local_id"],
          status: row["access"].upcase,
          origin: origin
        )
      end
    end
  end
end
