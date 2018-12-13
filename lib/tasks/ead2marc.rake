input_dir = ENV['EAD2MARC_INPUT'] || Rails.root.join('spec', 'fixtures', 'ead')
output_dir = ENV['EAD2MARC_OUTPUT'] || Rails.root.join('tmp', 'ead2marc')
solr_url = ENV['SET_URL'] || 'http://localhost:8983/solr/orangelight-core-development'

ns = { ead: "urn:isbn:1-931666-22-9" }

def norm(s)
  CGI.unescapeHTML(s.to_s.gsub(/\s+/, " ").strip)
end

def format_dates(dates)
  return norm(dates.first.text) if dates.length == 1

  incl_date = dates.select { |d| d.attribute("type").value == "inclusive" }
  bulk_date = dates.select { |d| d.attribute("type").value == "bulk" }
  "#{norm(incl_date.first.text)} (bulk #{norm(bulk_date.first.text)})"
end

def parse_control(s, parse_dates = false)
  s.map do |val|
    source = val.attribute("source").to_s
    uri = val.attribute("authfilenumber")&.value
    uri = nil unless uri&.start_with?("http")
    values = norm(val.text).split(" -- ").map { |v| norm(v) }

    dates = nil
    if parse_dates && values[0].match?(/, \d/)
      parts = values[0].rpartition(", ")
      values[0] = parts.first
      dates = parts.last
    end
    { values: values, dates: dates, source: source, uri: uri }
  end
end

# probably only care about identifying time periods, e.g., "20th Century"
def code_for(s)
  s.match?(/^\d/) ? "y" : "x"
end

namespace :ead2marc do
  desc "Convert EAD XML to MARC XML"
  task :convert do
    Dir["#{input_dir}/*.xml"].each do |ead_file|
      puts ead_file
      ead = File.open(ead_file) do |f|
        Nokogiri::XML(f, &:noent)
      end

      # id
      eadid = ead.xpath("/ead:ead/ead:eadheader/ead:eadid", ns)
      id = eadid.text.to_s
      ark = eadid.attribute("url").value

      # location
      loc = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:physloc[@type='code']/text()", ns)

      # basic
      title = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:unittitle/text()", ns)
      dates = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:unitdate", ns)
      date_string = format_dates(dates)

      extent = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:physdesc/ead:extent/text()", ns).map(&:to_s)
      if extent.length > 1
        extent[1].gsub!(/^/, "(")
        extent[-1].gsub!(/$/, ")")
      end
      access = ead.xpath("/ead:ead/ead:archdesc/ead:descgrp/ead:accessrestrict//text()", ns).map { |e| norm(e) }.reject(&:empty?)

      bioghist = ead.xpath("/ead:ead/ead:archdesc/ead:bioghist//text()", ns).to_s
      abstract = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:abstract//text()", ns)
      lang = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:langmaterial/ead:language", ns).map do |e|
        e.attribute("langcode").value
      end
      pers_elem = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:origination/ead:persname", ns)
      pers_name = pers_elem.text.to_s unless pers_elem.empty?
      pers_uri = pers_elem.attribute("authfilenumber") unless pers_elem.empty?
      corp_elem = ead.xpath("/ead:ead/ead:archdesc/ead:did/ead:origination/ead:corpname", ns)
      corp_name = corp_elem.text.to_s unless corp_elem.empty?
      corp_uri = corp_elem.attribute("authfilenumber") unless corp_elem.empty?

      # contents
      contents = ead.xpath("/ead:ead/ead:archdesc/ead:dsc/ead:c/ead:did/ead:unittitle/text()", ns).map(&:to_s).join("; ")

      # subjects
      persnames = ead.xpath("/ead:ead/ead:archdesc/ead:controlaccess/ead:persname", ns)
      corpnames = ead.xpath("/ead:ead/ead:archdesc/ead:controlaccess/ead:corpname", ns)
      subjects = ead.xpath("/ead:ead/ead:archdesc/ead:controlaccess/ead:subject", ns)
      genres = ead.xpath("/ead:ead/ead:archdesc/ead:controlaccess/ead:genreform", ns)
      occupations = ead.xpath("/ead:ead/ead:archdesc/ead:controlaccess/ead:occupation", ns)

      record = MARC::Record.new

      # codes
      record.append(MARC::ControlField.new("001", id.tr('.', '-')))
      record.append(MARC::DataField.new("041", " ", " ", *lang.map { |code| ["a", code.to_s] }))

      # names
      if pers_name
        opts = [["a", norm(pers_name)]]
        opts << ["0", norm(pers_uri)] if pers_uri
        record.append(MARC::DataField.new("100", " ", " ", *opts))
      end
      if corp_name
        opts = [["a", norm(corp_name)]]
        opts << ["0", norm(corp_uri)] if corp_uri
        record.append(MARC::DataField.new("110", " ", " ", *opts))
      end

      # title
      record.append(MARC::DataField.new("245", " ", " ", ["a", norm(title)], ["f", date_string]))

      # notes
      record.append(MARC::DataField.new("300", " ", " ", *extent.map { |ex| ["a", norm(ex)] }))
      record.append(MARC::DataField.new("351", " ", " ", ["a", norm(contents)]))
      record.append(MARC::DataField.new("506", " ", " ", *access.map { |ac| ["a", norm(ac)] }))
      record.append(MARC::DataField.new("520", " ", " ", ["a", norm(abstract)]))
      record.append(MARC::DataField.new("545", " ", " ", ["a", norm(bioghist)]))

      # control fields
      parse_control(corpnames, true).each do |corp|
        opts = [["a", corp[:values][0]]]
        opts << ["0", corp[:uri]] if corp[:uri]
        record.append(MARC::DataField.new("610", "2", "0", *opts))
      end
      parse_control(subjects).each do |sub|
        opts = [["a", sub[:values][0]], *sub[:values][1..-1].map { |x| [code_for(x), x] }]
        opts << ["0", sub[:uri]] if sub[:uri]
        opts << ["2", sub[:source]] if sub[:source]
        record.append(MARC::DataField.new("650", " ", "0", *opts))
      end
      parse_control(genres).each do |gen|
        opts = [["a", gen[:values][0]]]
        opts << ["2", gen[:source]] if gen[:source]
        record.append(MARC::DataField.new("655", " ", "7", *opts))
      end
      parse_control(occupations).each do |occ|
        opts = [["a", occ[:values][0]], *occ[:values][1..-1].map { |x| ["x", x] }] # XXX subfield codes
        opts << ["2", occ[:source]] if occ[:source]
        record.append(MARC::DataField.new("656", " ", "7", *opts))
      end
      parse_control(persnames, true).each do |pers|
        opts = [["a", pers[:values][0]]]
        opts << ["d", pers[:dates]] if pers[:dates]
        pers[:values][1..-1].each { |x| opts << ["x", x] }
        opts << ["0", pers[:uri]] if pers[:uri]
        record.append(MARC::DataField.new("600", "1", " ", *opts))
      end

      # ids
      hid = "#{id}.0"
      record.append(MARC::DataField.new("852", " ", " ", ["0", hid], ["h", id], *loc.map { |code| ["b", code.to_s] }))
      record.append(MARC::DataField.new("866", " ", "0", ["0", hid], ["a", "Stuff goes here"]))
      record.append(MARC::DataField.new("856", "4", "2", ["u", ark], ["z", "Princeton University Library Finding aid:"]))

      # write file
      FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
      File.open("#{output_dir}/#{id}.xml", "w") { |f| f.puts record.to_xml }
    end
  end

  desc "Index converted records"
  task :index do
    Dir["#{output_dir}/*.xml"].each do |f|
      puts f
      sh "traject -c marc_to_solr/lib/traject_config.rb -u #{solr_url} #{f}"
    end
    IndexFunctions.rsolr_connection(solr_url).commit
  end
end
