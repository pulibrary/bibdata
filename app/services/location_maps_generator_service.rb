class LocationMapsGeneratorService
  def self.generate
    new.generate
  end

  def self.generate_from_templates
    new.generate_from_templates
  end

  attr_reader :base_path, :logger
  def initialize(base_path: Rails.root.join('marc_to_solr', 'translation_maps'), logger: Rails.logger)
    @base_path = base_path
    @logger = logger
  end

  def generate
    unless holding_locations_table_exists?
      logger.warn("Failed to seed the holding locations for Traject as the database table has not been created. Please invoke bundle exec rake db:create")
      return
    end

    lib_display = {}
    locations_display = {}
    locations.each do |holding|
      holding_code = holding['code']
      lib_label = holding.library['label']
      holding_label = holding['label'] == '' ? lib_label : holding['label']
      lib_display[holding_code] = lib_label
      locations_display[holding_code] = holding_label
    end

    write_file('location_display.rb', lib_display)
    write_file('locations.rb', locations_display)
  end

  def generate_from_templates
    copy_template('locations.rb.tmpl')
    copy_template('location_display.rb.tmpl')
    copy_template('holding_library.rb.tmpl')
  end

  private

    def copy_template(template_name)
      output_file_name = template_name.gsub('.tmpl', '')
      output_file_path = file_path(output_file_name)
      return if File.exist?(output_file_path)
      template_file_path = file_path(template_name)
      FileUtils.cp(template_file_path, output_file_path)
    end

    def file_path(name)
      File.join(base_path, name)
    end

    def holding_locations_table_exists?
      ActiveRecord::Base.connection.table_exists?('locations_holding_locations')
    rescue StandardError => database_error
      Rails.logger.warn("Failed to seed the holding locations for Traject due to a database error: #{database_error}.")
      false
    end

    def locations
      Locations::HoldingLocation.all
    end

    def write_file(file_name, values)
      path = file_path(file_name)
      File.open(path, 'w') do |file|
        PP.pp(values, file)
      end
    end
end
