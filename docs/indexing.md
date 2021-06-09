# Indexing

WIP / DRAFT: This documentation is in migration from https://docs.google.com/document/d/1bHvgfgyUmDXV7ROqEZFaRxJFEYhSSUbeQoQT883GMWg/edit#

This document describes the source data indexed to the catalog index and the process for building a full catalog index.

## Source: Alma
The Alma ILS is the source of princeton's MARC data, both physical and electronic resources. More than 11 million MARC records index from Alma.

Alma MMS ids start with 99 and end with 6421

## Source: SCSB
About 6 million items shared from Columbia and NYPL pulled through HTC’s shared collection software https://github.com/ResearchCollectionsAndPreservation/scsb

These files are on an aws s3 bucket; the password is in lastpass under SCS Prod S3 Keys in the shared `bibdata` directory. The file path is SCSB > data-exports > PUL > MARCXml > Full. There are .zip files there and .csv files. The zip files contain the MARC dumps.

Frequency of updates: once per day

SCSB ids start with ‘SCSB’

## Source: Theses
About 68,800 senior theses pulled from the OIT Dataspace repository http://dataspace.princeton.edu/jspui/handle/88435/dsp019c67wm88m

Frequency of updates: Once per year. The Mudd Manuscript Library - Collections Cordinator will contact the Orangelight tech liaison and request the senior theses to be loaded into the catalog.

The https://github.com/pulibrary/orangetheses repository is used to pull the theses from dspace. 

A thesis record id starts with ‘dsp’. To search the catalog for all the indexed dspace theses: `https://catalog-alma-qa.princeton.edu/catalog?utf8=%E2%9C%93&search_field=all_fields&q=id%3Adsp*`

## Source: Numismatics
Numismatics data comes from Figgy via the rabbitmq. Incremental indexing is pulled in through orangelight code and so doesn't come through bibdata, but bibdata has a rake task to bulk index all the coins for initial full index creating.

## Solr Machines and Collections

The Catalog index is currently on a solrcloud cluster with 2 shards and a replication factor of 3. The solr machines (lib-solr-prod4, lib-solr-prod5, and lib-solr-prod6) are behind the load balancer and applications should access them via http://lib-solr8-prod.princeton.edu:8983 .

The collections `catalog-producion1` and `catalog-production2` are swapped as needed and should be accessed via the aliases `catalog-production` and `catalog-reindex`

The staging catalog uses http://lib-solr8-staging.princeton.edu:8983/solr/catalog-staging

## Creating a Full Index

### Select a collection

Tunnel to the solr admin panel using the cap task in pulibrary/pul_solr:

$ bundle exec cap solr8-staging solr:console

Click the 'collections' menu item and consult the `catalog-alma-staging` alias to see which collection is currently in use. Delete the other one and recreate it with the same settings.

Create an alias called `catalog-alma-staging-reindex` and point it to the new collection.

### Index Princeton's MARC records (Alma)

SSH to a bibdata machine and start a tmux session

as deploy user, in `/opt/marc_liberaton/current`

`$ RAILS_ENV=production UPDATE_LOCATIONS=false SET_URL=http://lib-solr8-staging.princeton.edu:8983/solr/catalog-alma-staging-reindex bin/rake liberate:full --silent >> /tmp/full_reindex_[YYYY-MM-DD].log 2>&1`

This step takes about 21 hours

### Index Partner SCSB records

If needed, pull the most recent SCSB full dump records into a dump file:

- as deploy user, in `/opt/marc_liberaton/current`
- `$ RAILS_ENV=production bundle exec rake scsb:import:full`
- It kicks off an import job

Takes 14-15 hours to complete. As they download and unpack they will be placed
in `/tmp/updates/` and as they are processed they will be moved to `/data/marc_liberation_files/scsb_update_files/`; you can follow the progress by listing the files in these directories.

Once the files are all downloaded and processed, index them with

`$ SET_URL=http://lib-solr8-staging.princeton.edu:8983/solr/catalog-alma-staging-reindex RAILS_ENV=production bundle exec rake scsb:full > /tmp/scsb_full_index_2021-06-3.log 2>&1`

### Index Theses

SSH to the bibdata machine that is used for indexing (bibdata-alma-staging) and start a tmux session

as deploy user, in `/opt/marc_liberaton/current`

`$ FILEPATH=/home/deploy/theses.json bin/rake orangetheses:cache_theses`

This step takes around 10 minutes. It will create a `theses.json` file in `home/deploy`. Post the file with:

`curl 'http://lib-solr8-staging.princeton.edu:8983/solr/catalog-alma-staging/update?commit=true' --data-binary @/home/deploy/theses.json -H 'Content-type:application/json'`

### Index Numismatic Coins

- as deploy user, in `/opt/marc_liberaton/current`
- `$ SET_URL=http://lib-solr8-staging.princeton.edu:8983/solr/catalog-alma-staging-reindex RAILS_ENV=production bundle exec rake numismatics:index:full`
- It will show a progress bar as it runs. Takes an hour or less.
