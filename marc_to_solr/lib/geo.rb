# geo.rb
# extract geo-related data from MARC

def decimal_coordinate record
  coverage = []
  Traject::MarcExtractor.cached('034defg').collect_matching_lines(record) do |field, _spec, _extractor|
    c = {}
    field.subfields.each do |s_field|
      c['w'] = s_field.value if (s_field.code == 'd') && valid_coordinate_format?(s_field.value, record)
      c['e'] = s_field.value if (s_field.code == 'e') && valid_coordinate_format?(s_field.value, record)
      c['n'] = s_field.value if (s_field.code == 'f') && valid_coordinate_format?(s_field.value, record)
      c['s'] = s_field.value if (s_field.code == 'g') && valid_coordinate_format?(s_field.value, record)
    end
    if c.length != 4
      # turning of geo coordinate logging for now
      # logger.error "#{record['001']} - missing coordinate"
      break
    end
    coverage << "northlimit=#{c['n']}; eastlimit=#{c['e']}; southlimit=#{c['s']}; westlimit=#{c['w']}; units=degrees; projection=EPSG:4326"
  end
  # turning of geo coordinate logging for now
  # logger.error "#{record['001']} - multiple 034s" if coverage.length > 1
  coverage.first
end

def valid_coordinate_format? c, _record
  return false unless c =~ /^[-+]?[0-9]*\.?[0-9]+$/
  true
end
