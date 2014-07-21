# Traject config goes here
require 'traject/macros/marc21_semantics'
extend Traject::Macros::Marc21Semantics

settings do
  # Where to find solr server to write to
  provide "solr.url", "http://localhost:8983/solr"

  # If you are connecting to Solr 1.x, you need to set
  # for SolrJ compatibility:
  # provide "solrj_writer.parser_class_name", "XMLResponseParser"

  # solr.version doesn't currently do anything, but set it
  # anyway, in the future it will warn you if you have settings
  # that may not work with your version.
  provide "solr.version", "4.6.0"

  # default source type is binary, traject can't guess
  # you have to tell it.
  provide "marc_source.type", "xml"

  # various others...
  provide "solrj_writer.commit_on_close", "true"

  # By default, we use the Traject::MarcReader
  # One altenrnative is the Marc4JReader, using Marc4J. 
  # provide "reader_class_name", "Traject::Marc4Reader"
  # If we're reading binary MARC, it's best to tell it the encoding. 
  provide "marc4j_reader.source_encoding", "UTF-8" # or 'UTF-8' or 'ISO-8859-1' or whatever. 
end

to_field 'id', extract_marc("001", :first => true)
to_field 'title_sort',        marc_sortable_title

