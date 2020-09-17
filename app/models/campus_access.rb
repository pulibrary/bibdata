require 'csv'

class CampusAccess < ActiveRecord::Base
  class << self
    def has_access?(uid)
      where(uid: uid).count.positive?
    end

    # single column CSV file that can be used by libcal and others who need a list of active users
    def to_csv
      ::CSV.generate(headers: false) do |csv|
        all.each do |user|
          csv << [user.uid]
        end
      end
    end

    def load_access(xlsx_filename, header_rows=4, trailer_rows=4)
      return unless File.exist?(xlsx_filename)
      unique_users = load_users(xlsx_filename, header_rows, trailer_rows)
      CampusAccess.transaction do
        delete_all # chosen for speed If call backs are needed we should use destroy_all
        unique_users.each do |user|
          create(uid: user)
        end
      end
    end

    private
      def load_users(xlsx_filename, header_rows, trailer_rows)
        workbook = RubyXL::Parser.parse(xlsx_filename)
        worksheet = workbook[0]
        users = []
        header_rows
        for row_number in (header_rows-1)..(worksheet.count-(trailer_rows+1))
          row = worksheet[row_number]
          course = row[0].value
          access = row[11].value
          # To be allowed in the libraries the user must have taken 1534 (Fall 2020 COVID-19 Training For Undergraduate and Graduate Students) or 1512 (Safe Practices for Resumption of On-Campus Operations)
          users << row[2].value if (course ==  1534 || course == 1512) && access == "Y"
        end
        users.uniq
      end
  end
end
