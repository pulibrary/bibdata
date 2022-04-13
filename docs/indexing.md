# Indexing

This document describes the source data indexed to the catalog index and the process for building a full catalog index.

This documentation was migrated from https://docs.google.com/document/d/1bHvgfgyUmDXV7ROqEZFaRxJFEYhSSUbeQoQT883GMWg/edit#, which is now deprecated.

## Source: Alma
The Alma ILS is the source of princeton's MARC data, both physical and electronic resources. More than 11 million MARC records index from Alma.

Alma MMS ids start with 99 and end with 3506421

Frequency of updates: 4x per day

## Source: SCSB
About 6 million items shared by our ReCAP Partners, Columbia, NYPL, and Harvard, pulled through HTC’s shared collection software https://github.com/ResearchCollectionsAndPreservation/scsb

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

The Catalog index is currently on a solrcloud cluster with 2 shards and a replication factor of 3 and maxShardsPerNode of 2. The solr machines (lib-solr-prod4, lib-solr-prod5, and lib-solr-prod6) are behind the load balancer and applications should access them via http://lib-solr8-prod.princeton.edu:8983 .

The collections `catalog-alma-production1` and `catalog-alma-production2` are swapped as needed and should be accessed via the aliases `catalog-alma-production` and `catalog-alma-production-rebuild`

The staging catalog uses http://lib-solr8-staging.princeton.edu:8983/solr/catalog-alma-staging and also has a rebuild index, `catalog-alma-staging-rebuild`.

## Accessing the solr admin UI

Tunnel to the solr admin panel using the cap task in pulibrary/pul_solr:

$ bundle exec cap [solr8-production || solr8-staging] solr:console

You can select a collection and use the "query" menu option to check how many documents are in the index.

## Creating a Full Index

Before you begin indexing, [check the solr cloud health](#check-solr-cloud-health) and make sure all replicas are behaving as expected.

### Clear the rebuild collection

ssh to an orangelight webserver and verify that the index in use is `catalog-alma-production` by checking `cat /home/deploy/app_configs/orangelight | grep SOLR`
webserver. You can find the webserver machine names in the capistrano environments in https://github.com/pulibrary/orangelight/tree/main/config/deploy

Go to the solr admin UI (see above).

- Select the `catalog-alma-production-rebuild` collection from the dropdown
- Select the `documents` menu item
- Select 'xml' from the 'Document Type' dropdown
- Enter `<delete><query>*:*</query></delete>` in the 'Document(s)' form box
- Click "Submit Document"

### Index Princeton's MARC records (Alma)

#### Full dump

You can go to the bibdata UI Events page to see the most recent full record dump. (https://bibdata.princeton.edu/events) (Look for the most recent All Records to see what will be processed when you run the rake task)

SSH to a bibdata machine as deploy user (Find a worker machine in your environment https://github.com/pulibrary/bibdata/tree/main/config/deploy)

```
tmux new -s full-index
$ cd /opt/marc_liberation/current
$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild bundle exec rake liberate:full
CTRL+b d (to detach from tmux)
```

Indexing jobs for each DumpFile in the dump will be run in the background. To watch the progress of the index, you can go to the bibdata web UI, login, and go to /sidekiq.

Once the full dump is finished indexing, the IndexManager will queue up dump
files for each relevant incremental dumps until all the Alma records are
indexed.

To keep tabs on how long the individual dump files take to index you can look at sidekiq DumpFileIndexJobs in [APM on datadog](https://app.datadoghq.com/apm/resource/sidekiq/sidekiq.job/3cb3f9643d54b111?query=env%3Anone%20service%3Asidekiq%20operation_name%3Asidekiq.job%20resource_name%3ADumpFileIndexJob%20-host%3Abibdata-alma-staging1%20-host%3Abibdata-alma-worker-staging1&cols=log_duration%2Clog_http.method%2Clog_http.status_code%2Ccore_error.type%2Ccore_operation_name%2Ccore_status%2Ccore_type%2Ctag_name%2Ctag_role%2Ctag_source%2Clog_trace.origin.service%2Clog_trace.origin.operation_name%2Ccore_host&env=none&index=apm-search&spanID=3126729460444177693&topGraphs=latency%3Alatency%2CbreakdownAs%3Apercentage%2Cerrors%3Acount%2Chits%3Arate&start=1629732542112&end=1629818942112&paused=false), filtered to exclude the staging machines.

Takes 6-7 hours to complete.

### Index Partner SCSB records

If needed, use the SCSB API to request new full dump records from the system to be generated into the SCSB bucket. EUS can help with this step.

If needed, pull the most recent SCSB full dump records into a dump file:

SSH to a bibdata machine as deploy user (Find a worker machine in your environment https://github.com/pulibrary/bibdata/tree/main/config/deploy)
```
$ tmux attach-session -t full-index
$ cd /opt/marc_liberation/current
$ bundle exec rake scsb:import:full
CTRL+b d (to detach from tmux)
```
This kicks off an import job which will return immediately.  This can be monitored in [sidekiq busy queue](https://bibdata.princeton.edu/sidekiq/busy) or [sidekiq waiting queue](https://bibdata.princeton.edu/sidekiq/queues/default)

Takes 24-25 hours to complete. As they download and unpack they will be placed
in `/tmp/updates/` and as they are processed they will be moved to `/data/marc_liberation_files/scsb_update_files/`; you can follow the progress by listing the files in these directories.

Once the files are all downloaded and processed, index them with

`$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild bundle exec rake scsb:full`

Indexing jobs for each DumpFile in the dump will be run in the background. To watch the progress of the index, you can login and go to /sidekiq.

This will also index any incremental files we have that were generated after the full dump files.

### Index Theses

SSH as the deploy user to the bibdata worker machine that is used for indexing https://github.com/pulibrary/bibdata/blob/7284a2364a8c1eb5af70f8e79b80a44eb546a4bc/config/deploy/production.rb#L11-L12 and start a tmux session. `ssh deploy@bibdata-alma-worker1`

as deploy user, in `/opt/marc_liberation/current`

```
$ tmux attach-session -t full-index
$ cd /opt/marc_liberation/current
$ mv /home/deploy/thesis.json /home/deploy/thesis-<date>.json 
$ FILEPATH=/home/deploy/theses.json bundle exec rake orangetheses:cache_theses
CTRL+b d (to detach from tmux)
```

This step takes around 10 minutes. It will create a `theses.json` file in `home/deploy`. Post the file with:

```
$ tmux attach-session -t full-index
$ cd /opt/marc_liberation/current
$ curl 'http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild/update?commit=true' --data-binary @/home/deploy/theses.json -H 'Content-type:application/json'
CTRL+b d (to detach from tmux)
```


### Index Numismatic Coins

Before running this task, turn off the sneakers workers on production so that any updates that come through after the full index has been generated will be included in the new index and not lost when you swap out the old index.

To turn off sneakers workers:
- cd in your local princeton_ansible directory -> pipenv shell -> ansible orangelight_production -u pulsys -m shell -a "sudo service orangelight-sneakers stop"

To index the coins:

- as deploy user, in `/opt/marc_liberation/current`
- `$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild bundle exec rake numismatics:index:full 2> /tmp/numismatics_index_[date].log`
- It will show a progress bar as it runs. Takes 30 min to an hour.
- Note that the default log writes to STDERR to distinguish its output from the progress bar

### Logs

Many of these tasks output log messages.

Because traject does not log to datadog we lose log output for indexing that runs in the background. See https://github.com/pulibrary/bibdata/issues/1507

### Index the latest Alma changes

There might be new incremental updates from Alma between the time the full reindex finishes and the index swap. Index these latest changes:

SSH to the bibdata alma worker machine that is used for indexing https://github.com/pulibrary/bibdata/blob/7284a2364a8c1eb5af70f8e79b80a44eb546a4bc/config/deploy/production.rb#L11-L12 and start a tmux session.

```
$ cd /opt/marc_liberation/current
$ SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild bundle exec rake liberate:incremental
```

### Index the latest SCSB changes

There might be new SCSB updates from Alma between the time the SCSB export started and the index swap. Set the TIMESTAMP to be the next day of when the SCSB export started (as long as the export started after 6am EST). Index these latest SCSB changes:
example: If the SCSB reindex started on '2021-10-15'. Set the TIMESTAMP= '2021-10-15'.

SSH to the bibdata alma worker machine that is used for indexing https://github.com/pulibrary/bibdata/blob/7284a2364a8c1eb5af70f8e79b80a44eb546a4bc/config/deploy/production.rb#L11-L12 and start a tmux session.

```
$ tmux attach-session -t full-index
$ cd /opt/marc_liberation/current
$ TIMESTAMP="2021-10-15" SET_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild bundle exec rake scsb:latest
CTRL+b d (to detach from tmux)
```

### Hook up your dev instance to the new index to see how it looks

- Set up an ssh tunnel to the solr index (you can use the pul_solr cap task given
above to do this)
- From your local orangelight checkout, run rails and point it to the solr url via your tunnel: `SOLR_URL=http://localhost:[port]/solr/catalog-alma-production-rebuild bin/rails s`
- Go to localhost:3000 > advanced search > holding location: pul > search
- This limits results to items from alma
- Total number of results tells you how many records are in the index
- In advanced search > holding location, search for scsbcul and scsbnypl (and soon scsbhl) to see results only from SCSB indexed records.
- Do the same search in production and compare the numbers.
- Any other spot checks you like to do? Add them here.

### Check solr cloud health

Before you swap in the new index, make sure that the solr cloud is all working as expected:

1. [Open the solr console](#accessing-the-solr-admin-ui)
1. Open the Cloud sub-menu
1. Open the graph view
1. On the graph, make sure that every replica is green (active).
1. If there are any replicas that are not in an active state, fix the underlying solr infrastructure issue before indexing.

### Swap in the new index

Update the index managers to have the new solr_collection values.

```
$ tmux attach-session -t full-index
$ cd /opt/marc_liberation/current
$bundle exec rake index_manager:promote_rebuild_manager
CTRL+b d (to detach from tmux)
```

Then swap the rebuild collection to the production alias.

- Run the cap task on pul_solr to swap the aliases
- Make sure you use the right values for PRODUCTION and REBUILD. For example if you just built the full index on catalog-production2 and are swapping it into production do:
```
[PRODUCTION_ALIAS=catalog-alma-production REBUILD_ALIAS=catalog-alma-production-rebuild] PRODUCTION=[catalog-production2] REBUILD=[catalog-production3] bundle exec cap solr8-production alias:swap
```

Then turn sneakers workers back on:
- cd in your local princeton_ansible directory -> pipenv shell -> ansible orangelight_production -u pulsys -m shell -a "sudo service orangelight-sneakers start"

Then expire the rails cache to get the updated values on the front page of the catalog. You can do this by deploying the app.

## Other tasks

### Delete records from Solr, excluding SCSB and Thesis records
Tunnel to the solr box, go to admin panel, you can see how many records there are by submitting a blank query
- Ssh to marc_liberation box as deploy user
- `$ bin/rails c`
- `> solr_url = "http://lib-solr8-prod.princeton.edu:8983/solr/catalog-alma-production-rebuild"`
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
