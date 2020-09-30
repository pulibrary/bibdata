require 'csv'

class CampusAccess < ActiveRecord::Base
  def initialize(attributes)
    attributes[:uid] = attributes[:uid]&.downcase
    super(attributes)
  end

  class << self
    def has_access?(uid)
      where(uid: uid).count.positive?
    end

    # single column CSV file that can be used by libcal and others who need a list of active users
    def to_csv
      ::CSV.generate(headers: false) do |csv|
        all.find_each do |user|
          csv << ["#{user.uid}@princeton.edu"]
        end
      end
    end

    def load_access(xlsx_filename, header_rows = 4, trailer_rows = 4, additional_ids: [])
      unique_users = load_users(xlsx_filename, header_rows, trailer_rows)
      CampusAccess.transaction do
        delete_all if unique_users.count.positive? # delete_all chosen for speed If call backs are needed we should use destroy_all
        create_ids(unique_users)
        create_ids(additional_ids)
      end
    end

    private

      def create_ids(id_list)
        id_list.each do |user|
          create(uid: user)
        end
      end

      def load_users(xlsx_filename, header_rows, trailer_rows)
        return [] unless File.exist?(xlsx_filename)
        workbook = RubyXL::Parser.parse(xlsx_filename)
        worksheet = workbook[0]
        users = []
        header_rows
        ((header_rows - 1)..(worksheet.count - (trailer_rows + 1))).each do |row_number|
          row = worksheet[row_number]
          course = row[0].value
          access = row[11].value
          # To be allowed in the libraries the user must have taken 1534 (Fall 2020 COVID-19 Training For Undergraduate and Graduate Students) or 1512 (Safe Practices for Resumption of On-Campus Operations)
          users << row[2].value if (course == 1534 || course == 1512 || course == 1507) && access == "Y"
        end
        users.uniq
      end
  end
end
