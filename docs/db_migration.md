# Database migration

Operations will communicate with DACS regarding the database migration.
## Turn off Incremental Publishing
Login in Alma -> Resources -> Publishing Profiles -> (from the list) Icremental Publishing -> Edit -> Publishing Parameters -> Scheduling -> (select) Not Scheduled. 
## Turn off General Publishing
Login in Alma -> Resources -> Publishing Profiles -> (from the list) General Publishing -> Edit -> Publishing Parameters -> Scheduling -> (select) Not Scheduled.
## Operations will run the database migration
[Database migration](https://github.com/pulibrary/princeton_ansible/blob/154b913347024f971649696b51f63ebd87fc8f5c/playbooks/postgresql_db_migration.yml)
## When the migration completes deploy bibdata to production and staging
## Turn on Incremental Publishing
Login in Alma -> Resources -> Publishing Profiles -> (from the list) Icremental Publishing -> Edit -> Publishing Parameters -> Scheduling -> (select) Every 6 hours, staring at 04:00.
## Turn on General Publishing
Login in Alma -> Resources -> Publishing Profiles -> (from the list) General Publishing -> Edit -> Publishing Parameters -> Scheduling -> (select) Every 6 hours, staring at 04:00.
## Monitor [Honeybadger](https://www.honeybadger.io/) to make sure there are no database errors.
