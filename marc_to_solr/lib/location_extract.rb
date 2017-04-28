require 'json'
require 'pp'
require 'faraday'

def update_locations
  begin
    conn = Faraday.new(:url => 'https://bibdata.princeton.edu/locations/holding_locations.json')
    resp = conn.get do |req|
      req.options.open_timeout = 5
    end
    loc_serv = resp.body
    hash = JSON.parse(loc_serv)
    lib_display = {}
    longer_display = {}
    holding_library = {}
    hash.each do |holding|
      holding_code = holding['code']
      lib_label = holding['library']['label']
      holding_label = holding['label'] == '' ? lib_label : lib_label + ' - ' + holding['label']
      lib_display[holding_code] = lib_label
      longer_display[holding_code] = holding_label
      holding_library[holding_code] = holding['holding_library']['label'] if holding['holding_library']
    end

    ## Test collections from ReCAP
    lib_display['scsbcul'] = 'ReCAP'
    lib_display['scsbnypl'] = 'ReCAP'
    longer_display['scsbcul'] = 'ReCAP'
    longer_display['scsbnypl'] = 'ReCAP'
    File.open(File.expand_path('../../translation_maps/location_display.rb', __FILE__), 'w') { |file| PP.pp(lib_display, file) }
    File.open(File.expand_path('../../translation_maps/locations.rb', __FILE__), 'w') { |file| PP.pp(longer_display, file) }
    File.open(File.expand_path('../../translation_maps/holding_library.rb', __FILE__), 'w') { |file| PP.pp(holding_library, file) }
  rescue Faraday::TimeoutError # use existing locations if unable to connect
  end
end
