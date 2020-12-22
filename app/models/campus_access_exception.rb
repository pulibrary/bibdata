require 'csv'

class CampusAccessException
  attr_reader :current_exceptions, :invalid_exceptions, :netid_key, :name_key, :data

  def initialize(csv_filename = nil, netid_key: "NetID issued by Princeton", name_key: "full legal name - first - last")
    @current_exceptions = []
    @netid_key = netid_key
    @name_key = name_key
    if csv_filename.present? && File.exist?(csv_filename)
      rows = CSV.read(csv_filename, headers: true)
      @data = rows.map(&:to_h)
      @current_exceptions = @data.map { |row| row[netid_key] }
      @invalid_exceptions = []
    else
      @data = []
    end
  end

  def process_new_exceptions(new_exceptions_filename)
    @invalid_exceptions = []
    return unless new_exceptions_filename.present? && File.exist?(new_exceptions_filename)
    workbook = RubyXL::Parser.parse(new_exceptions_filename)
    worksheet = workbook[0]
    surname_idx = 0
    first_name_idx = 1
    employee_id_idx = 2
    (1..(worksheet.count - 1)).each do |row_number|
      user = row_to_values(worksheet[row_number])
      employee_id = user[employee_id_idx].to_s
      next if employee_id.blank? # spare rows in the excel spreedsheet
      access = CampusAccess.find_by(employee_id: employee_id.to_s.rjust(9, "0"))
      if access.present?
        @data << { name_key => "#{user[first_name_idx]} #{user[surname_idx]}", netid_key => access.uid } if !current_exceptions.include?(access.uid) && !access.access?
      else
        invalid_exceptions << "#{employee_id}, #{user[first_name_idx]} #{user[surname_idx]}"
      end
    end
  end

  def export
    ::CSV.generate(headers: true) do |csv|
      csv << if data.blank?
               [name_key, netid_key]
             else
               data[0].keys
             end
      data.each do |user|
        csv << user.values
      end
    end
  end

  def export_to_file(csv_filename)
    File.open(csv_filename, 'w') do |file|
      file.write export
    end
  end

  private

    def row_to_values(row)
      values = []
      0.upto(row.size - 1) do |idx|
        values << if row[idx].present?
                    row[idx].value
                  else
                    ""
                  end
      end
      values
    end
end
