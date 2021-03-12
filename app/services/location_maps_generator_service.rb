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
    holding_library = {}
    locations.each do |holding|
      holding_code = holding['code']
      lib_label = holding.library['label']
      holding_label = holding['label'] == '' ? lib_label : holding['label']
      lib_display[holding_code] = lib_label
      locations_display[holding_code] = holding_label
    end

    # The Alma::Locations misses the location code: rare$warf
    # As a result the locations.rb file does not include it.
    # Do we need to add this location code ?
    # It refers to: Western Americana: Reference Collection (WARF)
    holding_libraries.each do |library|
      holding_library[library.code] = library.label
    end

    write_file('location_display.rb', lib_display)
    write_file('locations.rb', locations_display)
    write_file('holding_library.rb', holding_library)
  end

  # Select the holding_libraries based on the holding location code from:
  # https://github.com/pulibrary/bibdata/blob/main/marc_to_solr/translation_maps/holding_library.rb.tmpl
  def holding_libraries
    holding_codes = ["recap$gp", "recap$pb", "recap$pf", "recap$pg", "recap$ph", "recap$pj",
                     "recap$pk", "recap$pl", "recap$pm", "recap$pn", "recap$pq", "recap$ps", "recap$pt", "recap$pw",
                     "recap$pz", "recap$qk", "recap$ql", "recap$qv", "recap$xc", "recap$xg", "recap$xm", "recap$xn",
                     "recap$xp", "recap$xr", "recap$xx", "recap$warf"]
    locations.select { |l| holding_codes.include?(l.code) }
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
