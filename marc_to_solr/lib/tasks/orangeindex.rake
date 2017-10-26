require 'json'
require 'faraday'
require 'zlib'
require 'rsolr'
require 'time'
require './lib/index_functions'

conn = Faraday.new(:url => 'https://bibdata.princeton.edu') do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

default_solr_url = 'http://localhost:8983/solr/blacklight-core-development'

desc "Index MARC against SET_URL, default sample fixtures against traject config solr.url"
task :index do
  if ENV['MARC']
    url_arg = ENV['SET_URL'] ? "-u #{ENV['SET_URL']}" : ''
    fixtures = ENV['MARC']
    sh "traject -c lib/traject_config.rb #{fixtures} #{url_arg}"
  end
end

desc "Index MARC_PATH files against SET_URL (default is production)"
task :index_folder do
  solr_url = ENV['SET_URL'] || default_solr_url
  Dir["#{ENV['MARC_PATH']}/*.xml"].sort.each {|fixtures| sh "rake index SET_URL=#{solr_url} MARC=#{fixtures}; true"}
end

desc "which chunks from BIB_DUMP didn't index against SET_URL?"
task :check do
  if ENV['BIB_DUMP']
    index_url = ENV['SET_URL'] || default_solr_url
    solr = RSolr.connect :url => index_url
    `awk 'NR % 50000 == 0 {print} END {print}' #{ENV['BIB_DUMP']}`.split("\n").each_with_index do |bib, i|
      puts i if solr.get('get', :params => {id: "#{bib}"})["doc"].nil?
    end
  end
end

desc "which of the BIBS given didn't index against SET_URL?"
task :check_given do
  if ENV['BIBS']
    index_url = ENV['SET_URL'] || default_solr_url
    solr = RSolr.connect :url => index_url
    `awk '{print}' #{ENV['BIBS']}`.split("\n").each do |bib|
      puts bib if solr.get('get', :params => {id: "#{bib}"})["doc"].nil?
    end
  end
end

desc "which chunks from BIB_DUMP index against SET_URL?"
task :check_included do
  if ENV['BIB_DUMP']
    index_url = ENV['SET_URL'] || default_solr_url
    solr = RSolr.connect :url => index_url
    `awk 'NR % 50000 == 0 {print} END {print}' #{ENV['BIB_DUMP']}`.split("\n").each_with_index do |bib, i|
      puts i unless solr.get('get', :params => {id: "#{bib}"})["doc"].nil?
    end
  end
end

desc "Deletes given BIB from SET_URL"
task :delete_bib do
  solr_url = ENV['SET_URL'] || default_solr_url
  if ENV['BIB']
    sh "curl '#{solr_url}/update?commit=true' --data '<delete><id>#{ENV['BIB']}</id></delete>' -H 'Content-type:text/xml; charset=utf-8'"
  else
    puts 'Please provide a BIB argument (BIB=####)'
  end
end

namespace :liberate do

  desc "Index VoyRec for given BIB, against SET_URL"
  task :bib do
    url_arg = ENV['SET_URL'] ? "-u #{ENV['SET_URL']}" : '' 
    if ENV['BIB']
      resp = conn.get "/bibliographic/#{ENV['BIB']}"
      File.write('/tmp/tmp.xml', resp.body)   
      sh "traject -c lib/traject_config.rb /tmp/tmp.xml #{url_arg}"
    else
      puts 'Please provide a BIB argument (BIB=####)'
    end
  end

  desc "Index VoyRec with all changed records since SET_DATE, against SET_URL"
  task :updates do
    solr_url = ENV['SET_URL'] || default_solr_url
    resp = conn.get '/events.json'
    comp_date = ENV['SET_DATE'] ? Date.parse(ENV['SET_DATE']) : (Date.today-1)
    all_events = JSON.parse(resp.body).select {|e| Date.parse(e['start']) >= comp_date && e['success'] && e['dump_type'] == 'CHANGED_RECORDS'}.each do |event| 
      IndexFunctions::update_records(event, solr_url).each do |marc_xml|
        IndexFunctions::unzip(marc_xml)
        sh "traject -c lib/traject_config.rb #{marc_xml}.xml -u #{solr_url}; true"
        File.delete("#{marc_xml}.xml")
        File.delete("#{marc_xml}.gz")
      end
      sh "curl '#{solr_url}/update/json?commit=true' --data-binary @/tmp/delete_ids.json -H 'Content-type:application/json'; true"
    end
  end

  desc "Index VoyRec updates on SET_DATE against SET_URL"
  task :on do
    solr_url = ENV['SET_URL'] || default_solr_url
    resp = conn.get '/events.json'
    if event = JSON.parse(resp.body).detect {|e| Date.parse(e['start']) == Date.parse(ENV['SET_DATE']) && e['success'] && e['dump_type'] == 'CHANGED_RECORDS'}
      IndexFunctions::update_records(event, solr_url).each do |marc_xml|
        IndexFunctions::unzip(marc_xml)
        sh "traject -c lib/traject_config.rb #{marc_xml}.xml -u #{solr_url}; true"
        File.delete("#{marc_xml}.xml")
        File.delete("#{marc_xml}.gz")
      end
      sh "curl '#{solr_url}/update/json?commit=true' --data-binary @/tmp/delete_ids.json -H 'Content-type:application/json'"
    end
  end

  desc "Index VoyRec with today's changed records, against SET_URL"
  task :latest do
    solr_url = ENV['SET_URL'] || default_solr_url
    resp = conn.get '/events.json'
    event = JSON.parse(resp.body).last
    if event['success'] && event['dump_type'] == 'CHANGED_RECORDS'
      IndexFunctions::update_records(event, solr_url).each do |marc_xml|
        IndexFunctions::unzip(marc_xml)
        sh "traject -c lib/traject_config.rb #{marc_xml}.xml -u #{solr_url}; true"
        File.delete("#{marc_xml}.xml")
        File.delete("#{marc_xml}.gz")
      end
      sh "curl '#{solr_url}/update/json?commit=true' --data-binary @/tmp/delete_ids.json -H 'Content-type:application/json'"      
    end
  end

  desc "Index latest full record dump against SET_URL"
  task :full do
    solr_url = ENV['SET_URL'] || default_solr_url
    resp = conn.get '/events.json'
    if event = JSON.parse(resp.body).select {|e| e['success'] && e['dump_type'] == 'ALL_RECORDS'}.last
      IndexFunctions::full_dump(event, solr_url).each do |marc_xml|
        IndexFunctions::unzip(marc_xml)
        sh "traject -c lib/traject_config.rb #{marc_xml}.xml -u #{solr_url}; true"
        File.delete("#{marc_xml}.xml")
        File.delete("#{marc_xml}.gz")
      end
    end
  end
end