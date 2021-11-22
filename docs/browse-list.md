# Call Numbers

Note: This documentation was migrated from https://docs.google.com/document/d/1bHvgfgyUmDXV7ROqEZFaRxJFEYhSSUbeQoQT883GMWg/edit#heading=h.oz6ax25g11u and needs to be updated

Notice that the rake tasks indicated in this document are in **Orangelight**, not in bibdata.

## Generating browse lists

To fully regenerate **all browse lists**:

For catalog-staging, ssh to a staging box (there are no workers for catalog-staging and the rake task needs to run on the catalog box).

For catalog production, ssh to catalog-indexer1.

- Ensure you're the deploy user
- `$ cd /opt/orangelight/current and run the command below.`
- `OL_DB_PORT=5432 bundle exec rake browse:all && OL_DB_PORT=5432 bundle exec rake browse:load_all`

Expected time: 5.5 - 6 hours.

## Troubleshooting

When **subject lists**, which is used in `Subject (browse)` in Orangelight, fail to generate and would like to run the rake task before it is scheduled: SSH as `deploy` user to the machine used to produce the browse lists (`catalog-indexer1|2|3`):

- Run the first rake task to generate the CSV file from solr data.
- `cd /opt/orangelight/current`
- `OL_DB_PORT=5432 bundle exec rake browse:subjects`

Expected time 1.5-2 hours.

- Run the second rake task to upload the CSV file in the postgres table.

- `OL_DB_PORT=5432 bundle exec rake browse:load_subjects`

Expected time: Less than 30 minutes.

See note about `schedule.rb` in the Troubleshooting section below to find out the exact machine.

When **call_numbers** fail to generate and would like to run the rake task before it is scheduled:

ssh to `catalog-indexer1`.

Currently the `call_numbers` task is deployed to run on `catalog-indexer1`. Check [schedule.rb in Orangelight](https://github.com/pulibrary/orangelight/blob/main/config/schedule.rb#L27) to confirm.

Create a backup of the `/tmp/call_number_browse_s.sorted` file in `/home/deploy/call_number_browse_s.sorted`.

Count the lines: `wc -l /tmp/call_number_browse_s.sorted`.

While on the right box, create a tmux session and run the `call_numbers` rake task:

```
cd /opt/orangelight/current
RAILS_ENV=production SOLR_URL=http://lib-solr-prod4.princeton.edu:8983/solr/catalog-production bundle exec rake browse:call_numbers --silent >> /tmp/cron_log_call_numbers.log 2>&1
```

It takes around 3 hours to complete. When it finishes successfully the output will be on `/tmp/call_number_browse_s.sorted`. Count the lines in the file `wc -l /tmp/call_number_browse_s.sorted` to ensure that there is not a big difference with the backup file which is located in `/home/deploy/call_number_browse_s.sorted` or the most recent file which is located `/tmp/call_number_browse_s.sorted`.

Then run the `load_call_numbers` rake task to ingest the data. This task expects the input file to be on `/tmp/call_number_browse_s.sorted`:

```
cd /opt/orangelight/current
RAILS_ENV=production SOLR_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-production bundle exec rake browse:load_call_numbers --silent >> /tmp/cron_log.log 2>&1
```
