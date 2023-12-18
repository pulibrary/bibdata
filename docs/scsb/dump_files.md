### Fetch and process the SCSB files into dump files

SSH to a bibdata machine as deploy user (Find a worker machine in your [environment](https://github.com/pulibrary/bibdata/tree/main/config/deploy)).
```
$ tmux attach-session -t full-index
$ cd /opt/bibdata/current
$ bundle exec rake scsb:import:full
CTRL+b d (to detach from tmux)
```
This kicks off an import job which will return immediately.  This can be monitored in [sidekiq busy queue](https://bibdata.princeton.edu/sidekiq/busy) or [sidekiq waiting queue](https://bibdata.princeton.edu/sidekiq/queues/default)

Takes 24-25 hours to complete. As they download and unpack they will be placed
in `/tmp/updates/` and as they are processed they will be moved to `/data/bibdata_files/scsb_update_files/`; you can follow the progress by listing the files in these directories.  You can also find the most recent Full Partner ReCAP Records from [the events page](https://bibdata.princeton.edu/events), and look at the dump files in its json.  Be sure not to deploy bibdata in the middle of this job, or else the job will have to start all over again from the beginning.