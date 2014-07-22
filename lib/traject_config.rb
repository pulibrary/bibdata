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
  provide "solr.version", "4.9.0"

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

# Author/Artist:
#    100 XX aqbcdek A aq
#    110 XX abcdefgkln A ab
#    111 XX abcdefgklnpq A ab
#    711 XX abcdefghklnpqstx
to_field 'author_display', extract_marc("100aqbcdek:110abcdefgkln:111abcdefgklnpq:711abcdefghklnpqstx", :trim_punctuation => true, :first => true)

# Uniform title:
#    130 XX apldfhkmnorst T ap
#    240 XX {a[%}pldfhkmnors"]" T ap

# Title:
#    245 XX abchknps
#to_field 'title_display', extract_marc("245abchknps")
# Compiled/Created:
#    245 XX fg
#to_field 'title_display', extract_marc("245abchknps")
# Edition
#    250 XX ab
# Published/Created:
#    260 XX abcefg
#    264 XX abc

# Medium/Support:
#    340 XX 3abcdefhl
# Electronic access:
#    3000
# Description:
#    254 XX a
#    255 XX abcdefg
#    342 XX 2abcdefghijklmnopqrstuv
#    343 XX abcdefghi
#    352 XX abcdegi
#    355 XX abcdefghj
#    507 XX ab
#    256 XX a
#    516 XX a
#    753 XX abc
#    755 XX axyz
#    300 XX 3abcefg
#    306 XX a
#    515 XX a
#    362 XX az
# Arrangement:
#    351 XX 3abc
# Translation of:
#    765 XX at
# Translated as:
#    767 XX at
# Issued with:
#    777 XX at
# Continues:
#    780 00 at
#    780 02 at
# Continues in part:
#    780 01 at
#    780 03 at
# Formed from:
#    780 04 at
# Absorbed:
#    780 05 at
# Absorbed in part:
#    780 06 at
# Separated from:
#    780 07 at
# Continued by:
#    785 00 at
#    785 02 at
# Continued in part by:
#    785 01 at
#    785 03 at
# Absorbed by:
#    785 04 at
# Absorbed in part by:
#    785 05 at
# Split into:
#    785 06 at
# Merged to form:
#    785 07 at
# Changed back to:
#    785 08 at
# Frequency:
#    310 XX ab
# Former frequency:
#    321 XX a
# Has supplement:
#    770 XX at
# Supplement to:
#    772 XX at
# Linking notes:
#    580 XX a
# Subseries of:
#    760 XX at
# Has subseries:
#    762 XX at
# Series:
#    400 XX abcdefgklnpqtuvx
#    410 XX abcdefgklnptuvx
#    411 XX acdefgklnpqtuv
#    440 XX anpvx
#    490 XX avx
#    800 XX abcdefghklmnopqrstuv
#    810 XX abcdefgklnt
#    811 XX abcdefghklnpqstuv
#    830 XX adfghklmnoprstv
#    840 XX anpv
# Other version(s):
#    3500 020Z020A
#    3500 020A020Z
#    3500 024A022A
#    3500 022A024A
#    3500 BBID776W
#    3500 BBID787W
#    3500 776X022A
#    3500 022A776X
#    3500 020A776Z
#    3500 776Z020A
# Contained in:
#    3500 BBID773W
# Restrictions note:
#    506 XX 3abcde
# Biographical/Historical note:
#    545 XX ab
# Summary note:
#    520 XX 3ab
# Notes:
#    500 XX 3a
#    501 XX a
#    503 XX a
#    502 XX a
#    504 XX ab
#    508 XX a
#    513 XX ab
#    514 XX abcdefghijkm
#    515 XX a
#    518 XX 3a
#    521 XX 3ab
#    522 XX a
#    523 XX a
#    525 XX a
#    527 XX a
#    534 XX abcefklmnpt
#    535 XX 3abcdg
#    536 XX abcdefgh
#    537 XX a
#    538 XX a
#    544 XX 3abcden
#    547 XX a
#    550 XX a
#    556 XX a
#    562 XX 3abcde
#    565 XX 3abcde
#    567 XX a
#    570 XX a
# Binding note:
#    563 XX au3
# Local notes:
#    590 XX a
#    591 XX a
#    592 XX a
# Rights and reproductions note:
#    540 XX 3abcd
# Exhibitions note:
#    585 XX 3a
# Participant(s)/Performer(s):
#    511 XX a
# Language(s):
#    546 XX 3a
# Script:
#    546 XX b
# Contents:
#    505 0X agrt
#    505 8X agrt
# Incomplete contents:
#    505 1X agrt
# Partial contents:
#    505 2X agrt
# Provenance:
#    561 XX 3ab
#    796 XX abcqde
#    797 XX abcqde
# Source of acquisition:
#    541 XX abcdefhno36
# Publications about:
#    581 XX az36
# Indexed in:
#    510 0X 3abc
#    510 1X 3abc
#    510 2X 3abc
# References:
#    510 3X 3abc
#    510 4X 3abc
# Cite as:
#    524 XX 23a
# Other format(s):
#    530 XX 3abcd
#    533 XX 3abcdefmn
# Cumulative index/Finding aid:
#    555 XX 3abcd
# Subject(s):
#    600 XX acdfklmnopqrst{v--%}{x--%}{y--%}{z--%} S abcdfklmnopqrtvxyz
#    610 XX abfklmnoprst{v--%}{x--%}{y--%}{z--%} S abfklmnoprstvxyz
#    611 XX abcdefgklnpqst{v--%}x--%}{y--%}{z--%} S abcdefgklnpqstvxyz
#    630 XX adfgklmnoprst{v--%}{x--%}{y--%}{z--%} S adfgklmnoprstvxyz
#    650 XX abc{v--%}{x--%}{z--%}{y--%} S abcvxyz
#    651 XX a{v--%}{x--%}{y--%}{z--%} S avxyz
# Form/Genre:
#    655 |7 a{v--%}{x--%}{y--%}{z--%} S avxyz
# Related name(s):
#    700 XX aqbcdefghklmnoprstx A aq
#    710 XX abcdefghklnoprstx A ab
# Place name(s):
#    752 XX abcd
# Other title(s):
#    246 XX abfnp
#    210 XX ab
#    211 XX a
#    212 XX a
#    214 XX a
#    222 XX ab
#    242 XX abchnp
#    243 XX adfklmnoprs
#    247 XX abfhnp
#    730 XX aplskfmnor
#    740 XX ahnp
# In:
#    773 XX 3abdghikmnoprst
# Constituent part(s):
#    774 XX abcdghikmnrstu
# ISBN:
#    020 XX a
# ISSN:
#    022 XX a
# SuDoc no.:
#    086 XX a
# Tech. report no.:
#    027 XX a
#    088 XX a
# Music publ. no.:
#    028 XX a
# Standard no.:
#    010 XX a
#    030 XX a
# Original language:
#    880 XX abc
# Related record(s):
#    3500 BBID774W
# Holdings information:
#    9000
