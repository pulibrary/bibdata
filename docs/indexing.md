# Indexing

This document describes the source data indexed to the catalog index and the process for building a full catalog index.

This documentation was migrated from https://docs.google.com/document/d/1bHvgfgyUmDXV7ROqEZFaRxJFEYhSSUbeQoQT883GMWg/edit#, which is now deprecated.

## Source: Alma
The Alma ILS is the source of princeton's MARC data, both physical and electronic resources. More than 11 million MARC records index from Alma.

Alma MMS ids start with 99 and end with 3506421

Frequency of updates: 4x per day

## Source: SCSB
About 6 million items shared by our ReCAP Partners, Columbia and NYPL, pulled through HTC’s shared collection software https://github.com/ResearchCollectionsAndPreservation/scsb

These files are on an aws s3 bucket; the password is in lastpass under SCS Prod S3 Keys in the shared `bibdata` directory. The file path is SCSB > data-exports > PUL > MARCXml > Full. There are .zip files there and .csv files. The zip files contain the MARC dumps.

Frequency of updates: once per day

SCSB ids start with ‘SCSB’

## Source: DSpace
About 68,800 senior theses pulled from the Dataspace repository http://dataspace.princeton.edu/jspui/handle/88435/dsp019c67wm88m

Frequency of updates: Once per year. The Mudd Manuscript Library - Collections Cordinator will contact the Orangelight tech liaison and request the senior theses to be loaded into the catalog.

The https://github.com/pulibrary/orangetheses repository is used to pull the theses from dspace.

A thesis record id starts with ‘dsp’. To search the catalog for all the indexed dspace theses: `https://catalog-alma-qa.princeton.edu/catalog?utf8=%E2%9C%93&search_field=all_fields&q=id%3Adsp*`

## Source: Numismatics
Numismatics data comes from Figgy via the rabbitmq. Incremental indexing is pulled in through orangelight code and so doesn't come through bibdata, but bibdata has a rake task to bulk index all the coins for initial full index creation and any time a full reindex may be needed.

## Solr Machines and Collections

The Catalog index is currently on a solrcloud cluster with 2 shards and a replication factor of 3. The solr machines (lib-solr-prod4, lib-solr-prod5, and lib-solr-prod6) are behind the load balancer and applications should access them via http://lib-solr8-prod.princeton.edu:8983 .

The collections `catalog-alma-production1` and `catalog-alma-production2` are swapped as needed and should be accessed via the aliases `catalog-alma-production` and `catalog-alma-rebuild`

The staging catalog uses http://lib-solr8-staging.princeton.edu:8983/solr/catalog-alma-staging and also has a rebuild index, `catalog-alma-staging-rebuild`.

## Accessing the solr admin UI

Tunnel to the solr admin panel using the cap task in pulibrary/pul_solr:

$ bundle exec cap [solr8-production || solr8-staging] solr:console

You can select a collection and use the "query" menu option to check how many documents are in the index.

## Creating a Full Index

### Clear the rebuild collection

ssh to an orangelight webserver and verify that the index in use is `catalog-alma-production` by checking `cat /home/deploy/app_configs/orangelight | grep SOLR`

Go to the solr admin UI (see above).

- Select the `catalog-alma-rebuild` collection from the dropdown
- Select the `documents` menu item
- Enter `{'delete': {'query': '*:*'}}` in the 'Document(s)' form box
- Click "Submit Document"

### Index Princeton's MARC records (Alma)

#### Full dump

You can go to the bibdata UI Events page to see the most recent full record dump.

SSH to a bibdata machine and start a tmux session.

as deploy user, in `/opt/marc_liberaton/current`

`$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-rebuild bin/rake liberate:full`

Indexing jobs for each DumpFile in the dump will be run in the background. To watch the progress of the index, you can go to the bibdata web UI, login, and go to /sidekiq.

Timing for this step is still being determined.

#### Incremental files created since the full dump

TODO: We don't currently have this job. See https://github.com/pulibrary/bibdata/issues/1518

Any incremental files created after the full dump also need to be indexed.

- Once the job has been created, instructions will be something like:
  - Determine the date of the last full bib dump. The date is stored in the `start` field of the Event. Use this date in SET_DATE below.
  - Full dumps are run once a week; you can see this by looking at the `General Publishing` job in Alma.
  - As deploy user in /opt/marc_liberation/current, run:
  - SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-rebuild SET_DATE=[yyyy-mm-dd or yyyy-mm-dd] bin/rake liberate:updates

### Index Partner SCSB records

If needed, use the SCSB API to request new full dump records from the system to be generated into the SCSB bucket. EUS can help with this step.

If needed, pull the most recent SCSB full dump records into a dump file:

- as deploy user, in `/opt/marc_liberaton/current`
- `$ bundle exec rake scsb:import:full`
- It kicks off an import job

Takes 14-15 hours to complete. As they download and unpack they will be placed
in `/tmp/updates/` and as they are processed they will be moved to `/data/marc_liberation_files/scsb_update_files/`; you can follow the progress by listing the files in these directories.

Once the files are all downloaded and processed, index them with

`$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-staging-rebuild bundle exec rake scsb:full`

Indexing jobs for each DumpFile in the dump will be run in the background. To watch the progress of the index, you can login and go to /sidekiq.

This will also index any incremental files we have that were generated after the full dump files.

### Index Theses

SSH to the bibdata worker machine that is used for indexing and start a tmux session

as deploy user, in `/opt/marc_liberaton/current`

`$ FILEPATH=/home/deploy/theses.json bin/rake orangetheses:cache_theses`

This step takes around 10 minutes. It will create a `theses.json` file in `home/deploy`. Post the file with:

`curl 'http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-rebuild/update?commit=true' --data-binary @/home/deploy/theses.json -H 'Content-type:application/json'`

### Index Numismatic Coins

Before running this task, turn off the sneakers workers on production so that any updates that come through after the full index has been generated will be included in the new index and not lost when you swap out the old index.

To turn off sneakers workers:
- cd in your local princeton_ansible directory -> pipenv shell -> ansible orangelight_alma_prod -u pulsys -m shell -a "sudo service orangelight-sneakers stop"

To index the coins:

- as deploy user, in `/opt/marc_liberaton/current`
- `$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-rebuild bundle exec rake numismatics:index:full 2> /tmp/numismatics_index_[date].log`
- It will show a progress bar as it runs. Takes 30 min to an hour.
- Note that the default log writes to STDERR to distinguish its output from the progress bar

### Logs

Many of these tasks output log messages.

Because traject does not log to datadog we lose log output for indexing that runs in the background. See https://github.com/pulibrary/bibdata/issues/1507

### Hook up your dev instance to the new index to see how it looks

- Set up an ssh tunnel to the solr index (you can use the pul_solr cap task given
above to do this)
- From your local orangelight checkout, run rails and point it to the solr url via your tunnel: `SOLR_URL=http://localhost:[port]/solr/catalog-rebuild rails s`
- Go to localhost:3000 > advanced search > holding location: pul > search
- This limits results to items from alma
- Total number of results tells you how many records are in the index
- In advanced search > holding location, search for scsbcul and scsbnypl (and soon scsbhl) to see results only from SCSB indexed records.
- Do the same search in production and compare the numbers.
- Any other spot checks you like to do? Add them here.

### Swap in the new index

- Run the cap task on pul_solr to swap the aliases
- Make sure you use the right values for PRODUCTION and REBUILD. For example if you just built the full index on catalog-production2 and are swapping it into production do:
```
PRODUCTION=catalog-production2 REBUILD=catalog-production1 bundle exec cap solr8-production alias:swap
```

To turn sneakers workers back on:
- cd in your local princeton_ansible directory -> pipenv shell -> ansible orangelight_alma_prod -u pulsys -m shell -a "sudo service orangelight-sneakers start"

## Other tasks

### Delete records from Solr, excluding SCSB and Thesis records
Tunnel to the solr box, go to admin panel, you can see how many records there are by submitting a blank query
- Ssh to marc_liberation box as deploy user
- `$ bin/rails c`
- `> solr_url = "http://lib-solr8-prod.princeton.edu:8983/solr/catalog-rebuild"`
- `> solr = RSolr.connect(url: solr_url)`
- `> solr.delete_by_query("id:[1 TO 999999999]")`
- `> solr.commit`

You can see the number of records now in the solr admin panel.

Query to get the SCSB:
- These are only the records that someone can get in the advanced search -> holding location -> scsbcul or scsbnypl.
- `> response_scsb = solr.get ‘select’, :params=> {:q => ‘id:SCSB*’}`

Query to delete SCSB:
- `> solr.delete_by_query("id:SCSB*")`

### Adding a replica

You have to specify the nodename in an unintuitive way, like `lib-solr-staging4.princeton.edu:8983_solr`. The full command to add a replica is, e.g. `pulsys@lib-solr-staging4:~$ curl "http://localhost:8983/solr/admin/collections?action=ADDREPLICA&collection=catalog-staging&shard=shard2&node=lib-solr-staging4.princeton.edu:8983_solr"
