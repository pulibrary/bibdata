# Call Numbers

Note: This documentation was migrated from https://docs.google.com/document/d/1bHvgfgyUmDXV7ROqEZFaRxJFEYhSSUbeQoQT883GMWg/edit#heading=h.oz6ax25g11u and needs to be updated

## Generating browse lists

To fully regenerate all browse lists:
`OL_DB_PORT=5432 bundle exec rake browse:all && OL_DB_PORT=5432 bundle exec rake browse:load_all`

Expected time: 5.5 - 6 hours.

## Troubleshooting

When browse lists fail to generate and would like to run the rake task before it is scheduled:
ssh to `lib-pulindexer1`. Check the crontab and make sure the rake task for the call numbers runs on this box. If not then check `lib-pulindexer2` and `lib-pulindexer3`.
create a backup of the `tmp/orangelight_name_titles.sorted` file. Count the lines: `wc -l /tmp/orangelight_name_titles.sorted`.
While on the right box, create a tmux session and run the call number rake task (`cd /opt/orangelight/current && RAILS_ENV=production SOLR_URL=http://lib-solr-prod4.princeton.edu:8983/solr/catalog-production bundle exec rake browse:call_numbers --silent >> /tmp/cron_log.log 2>&1`). It takes some time. When it finishes successfully count the lines in the file `wc -l /tmp/orangelight_name_titles.sorted` to ensure that there is not a big difference with the backup file which is located in `/home/deploy/orangelight_name_titles.sorted` or the most recent file which is located in `/tmp/orangelight_name_titles.sorted`.
The `/home/deploy/orangelight_name_titles.sorted` is a backup file from January.
Run `cd /opt/orangelight/current && RAILS_ENV=production SOLR_URL=http://lib-solr8-prod.princeton.edu:8983/solr/catalog-production bundle exec rake browse:load_call_numbers --silent >> /tmp/cron_log.log 2>&1`.
