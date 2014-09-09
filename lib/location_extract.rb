require 'json'
require 'open-uri'

def update_locations
	loc_serv = open('http://library.princeton.edu/searchit/requests/locationservice.php').read
	#file = File.read('lib/translation_maps/location_service.json')

	hash = JSON.parse(loc_serv)
	libdisplay = Hash.new
	longerdisplay = Hash.new
	hash.each do |key, value|
		libdisplay[key] = hash[key]["libraryDisplay"]
		if hash[key]["collectionDisplay"].nil?
			longerdisplay[key] = hash[key]["libraryDisplay"] 
		else
			longerdisplay[key] = hash[key]["libraryDisplay"] + ': ' + hash[key]["collectionDisplay"]
		end
	end

	File.open('lib/translation_maps/location_display.rb', 'w') { |file| file.write(libdisplay) }
	File.open('lib/translation_maps/locations.rb', 'w') { |file| file.write(longerdisplay) }
end