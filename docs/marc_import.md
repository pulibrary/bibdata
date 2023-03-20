# MARC File Import
If you have MARC file you can import it to Solr via Traject with the following commands:

```
FILE=/path/to/marc/file/filename.xml
SOLR_URL=http://localhost:8983/local-solr-index
bundle exec traject -c marc_to_solr/lib/traject_config.rb $FILE -u $SOLR_URL
```

If you just want to see what would be sent to Solr (but don't push the document to Solr) you can use instead:

```
FILE=/path/to/marc/file/filename.xml
bundle exec traject -c marc_to_solr/lib/traject_config.rb $FILE -w Traject::JsonWriter
```
OR with solr in any port:
```
traject -c marc_to_solr/lib/traject_config.rb path-to-xml/example.xml -u http://localhost:<solr-port-number>/solr/local-solr-index -w Traject::JsonWriter
```

### Example using lando and Princeton config
```bash
traject --debug-mode -c marc_to_solr/lib/traject_config.rb path-to-xml/example.xml -u http://bibdata.dev.solr.lndo.site/solr/bibdata-core-development -w Traject::PulSolrJsonWriter 2>&1
```
