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
    libdisplay = Hash.new
    longerdisplay = Hash.new
    hash.each do |holding|
      holding_code = holding["code"]
      lib_label = holding["library"]["label"]
      holding_label = holding["label"] == '' ? lib_label : lib_label + ' - ' + holding['label']
      libdisplay[holding_code] = lib_label
      longerdisplay[holding_code] = holding_label
    end

    ## Test collections from ReCAP
    libdisplay['scsbcul'] = 'ReCAP'
    libdisplay['scsbnypl'] = 'ReCAP'
    longerdisplay['scsbcul'] = 'ReCAP'
    longerdisplay['scsbnypl'] = 'ReCAP'

    File.open(File.expand_path('../../translation_maps/location_display.rb', __FILE__), 'w') { |file| PP.pp(libdisplay, file) }
    File.open(File.expand_path('../../translation_maps/locations.rb', __FILE__), 'w') { |file| PP.pp(longerdisplay, file) }
  rescue Faraday::TimeoutError # use existing locations if unable to connect
  end
end