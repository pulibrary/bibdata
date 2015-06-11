require 'json'
require 'open-uri'

def update_locations
	#loc_serv = open('http://library.princeton.edu/searchit/requests/locationservice.php').read
	loc_serv = open('http://bibdata.princeton.edu/locations/holding_locations.json').read
	#file = File.read('lib/translation_maps/location_service.json')

	hash = JSON.parse(loc_serv)
	libdisplay = Hash.new
	longerdisplay = Hash.new
	hash.each do |holding|
		holding_code = holding["code"]
		lib_label = holding["library"]["label"]
		holding_label = holding["label"] == '' ? lib_label : lib_label + ': ' + holding['label']
		libdisplay[holding_code] = lib_label
		longerdisplay[holding_code] = holding_label
	end

	File.open('lib/translation_maps/location_display.rb', 'w') { |file| file.write(libdisplay) }
	File.open('lib/translation_maps/locations.rb', 'w') { |file| file.write(longerdisplay) }
end