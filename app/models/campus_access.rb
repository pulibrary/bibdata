require 'csv'

class CampusAccess < ActiveRecord::Base
  FULL = "full".freeze
  TRAINED = "trained".freeze

  def initialize(attributes)
    attributes[:uid] = attributes[:uid]&.downcase
    super(attributes)
  end

  def access?
    category == FULL
  end

  class << self
    def has_access?(uid)
      where(uid: uid&.downcase, category: const_get("FULL")).count.positive?
    end

    # single column CSV file that can be used by libcal and others who need a list of active users
    def to_csv
      ::CSV.generate(headers: false) do |csv|
        where(category: const_get("FULL")).find_each do |user|
          csv << ["#{user.uid}@princeton.edu"]
        end
      end
    end

    def load_access(xlsx_filename, trained_file: nil, header_rows: 4, trailer_rows: 4, additional_ids: [])
      employee_id_lookup = {}
      unique_users = load_users(xlsx_filename, header_rows: header_rows, trailer_rows: trailer_rows, employee_id_lookup: employee_id_lookup)
      unique_trained_users = load_users(trained_file, header_rows: header_rows, trailer_rows: trailer_rows, filter: :filter_learn, employee_id_lookup: employee_id_lookup)
      full_ids = additional_ids | unique_users
      CampusAccess.transaction do
        delete_all if unique_users.count.positive? # delete_all chosen for speed If call backs are needed we should use destroy_all
        create_ids(full_ids, employee_id_lookup: employee_id_lookup)
        create_ids(unique_trained_users - full_ids, category: const_get("TRAINED"), employee_id_lookup: employee_id_lookup)
      end
    end

    def valid_courses
      # To be allowed in the libraries the user must have taken 1534 (Fall 2020 COVID-19 Training For Undergraduate and Graduate Students) or 1512 & 1507 (Safe Practices for Resumption of On-Campus Operations) or 1505 1507 (COVID-19 Safety Precautions)
      # 1586 (Spring 2021 COVID-19 Training For Students)
      # 1721 (Safe Practices for Resumption of On-Campus Operations)
      [1534, 1511, 1512, 1507, 1505, 1514, 1509, 1506, 1586, 1721]
    end

    private

      def create_ids(id_list, category: const_get("FULL"), employee_id_lookup:)
        id_list.each do |user|
          create(uid: user, category: category, employee_id: employee_id_lookup[user]&.to_s&.rjust(9, "0"))
        end
      end

      def load_users(xlsx_filename, header_rows:, trailer_rows:, filter: :filter_full, employee_id_lookup:)
        return [] unless xlsx_filename.present? && File.exist?(xlsx_filename)
        workbook = RubyXL::Parser.parse(xlsx_filename)
        worksheet = workbook[0]
        users = []
        header_rows
        ((header_rows - 1)..(worksheet.count - (trailer_rows + 1))).each do |row_number|
          row = worksheet[row_number]
          # To be allowed in the libraries the user must have taken 1534 (Fall 2020 COVID-19 Training For Undergraduate and Graduate Students) or 1512 (Safe Practices for Resumption of On-Campus Operations)
          id = send(filter, row)
          if id.present?
            users << id
            employee_id_lookup[id] = row[7].value
          end
        end
        users.uniq
      end

      def filter_full(row)
        course = row[0].value
        access = row[11].value
        row[2].value.downcase if valid_courses.include?(course) && access == "Y"
      end

      def filter_learn(row)
        course = row[1].value
        row[0].value.downcase if valid_courses.include?(course)
      end
  end
end
