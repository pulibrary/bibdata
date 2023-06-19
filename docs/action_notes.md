# Action notes

Action notes are stored in Solr as a JSON field called
`action_notes_1display`.  Its data come from the MARC
583 field.  It displays as a link in the catalog if
a 583$u is present, otherwise it displays as plain text.

Action notes are only indexed if the second indicator is
1 and one or more of the following is true:

* The record is a SCSB record
* The record is a PULFA record
* 583$8 is present
