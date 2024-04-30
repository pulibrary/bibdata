# Load data in database

This document describes the steps to dump the database from the bibdata production database and load the dump file into the staging database.

## Dump data from production 

1. ssh to one of the [bibdata production VMs](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L12-L15):

  `ssh deploy@bibdata-prod1`
  - Run:  
    `env | grep -i postgres` to find which [postgres production VM](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/postgresql#L8-L9), bibdata is connected to.
    `env | grep -i DB` to find the production database name in the env variable: BIBDATA_DB  

2. ssh to the postgres production VM that bibdata production is connected to:

  `ssh pulsys@lib-postgres-prod1` 
  - Run:  
    `sudo su - postgres` to connect to postgres
    `pg_dump -d bibdata_alma_production -Fc -f /tmp/bibdata_production_db.dump` to generate  the `bibdata_production_db.dump` dump file.

### Load data into the bibdata staging database  

1. ssh to one of the [bibdata staging VMs](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L7-L10):

  `ssh deploy@bibdata-alma-staging1`
  - Run:  
      `env | grep -i postgres` to find which [postgres staging VM](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/postgresql#L11-L12), bibdata staging is connected to.
      `env | grep -i DB` to find the staging database name in the env variable: `BIBDATA_DB`

2. scp the `bibdata_production_db.dump` dump file that you generated in the previous section - Dump data from production - to your local and then to the `/tmp/` directory in the postgres staging VM that bibdata staging is using. 
If the postgres production VM has the public key from the postgres staging VM then you can scp the file directly from postgres production into postgres staging.

3. ssh as pulsys in all the [bibdata staging machines](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L7-L10) and stop the nginx service:

e.g.: 
   `ssh pulsys@bibdata-alma-staging1`
   `sudo service nginx stop`


4. ssh to the postgres staging VM that bibdata staging is connected to:

   `ssh pulsys@lib-postgres-staging1`
   `sudo su - postgres` to connect to postgres
   `ls /tmp/` confirm that the file `bibdata_production_db.dump` you transferred in step 2 exists in `/tmp`. If it does not exist do not continue dropping the staging database. Go back to step 2 and make sure to transfer the dump file to `/tmp`.
   `dropdb bibdata_alma_staging` to drop the staging database
   `createdb -O bibdata bibdata_alma_staging` to create a new bibdata_alma_staging with role bibdata 
   
   `pg_restore -d bibdata_alma_staging  /tmp/bibdata_production_db.dump` to load the dump file into the bibdata_alma_staging database.

5. Deploy bibdata to the staging environment
   
   - From your local main branch deploy bibdata using capistrano to the staging environment.
   - OR deploy bibdata to the staging environment using [ansible tower](https://ansible-tower.princeton.edu/#/home).

6. ssh as pulsys in all the [bibdata staging machines](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/bibdata#L7-L10) and start the nginx service:

e.g.: 
   `ssh pulsys@bibdata-alma-staging1`
   `sudo service nginx start

7. Go to `https://bibdata-staging.princeton.edu/events` and make sure the application is working as expected and lists all the events that the production site has.

8. The files that are connected to these events exist in bibdata production `/data/bibdata_files`. 
For example: you want to test an issue on staging using the event with ID:6248:  
   1. From https://bibdata.princeton.edu/dumps/6248.json download the dump file that is attached to this event. It is the file `incremental_36489280620006421_20240423_130418[009]_new.tar.gz`. You can also find the file name by searching the database. The dump and event id are the same. The `tar.gz` file is saved in a dump_file object. :
      - `deploy@bibdata-alma1:/opt/bibdata/current$ bundle exec rails c`
      - `DumpFile.where(dump_id: 6248)` you should be able to see in attribute `path:` the `incremental_36489280620006421_20240423_130418[009]_new.tar.gz`.

   2. scp the file into one of the bibdata staging VMs:
       - scp the file to your local and then to `deploy@bibdata-alma-staging1:/data/bibdata_files`
       - Visit https://bibdata-staging.princeton.edu/dumps/6248.json. The webpage should not error. You can also confirm that the file is attached to this event by searching the bibdata staging DB.
       - `deploy@bibdata-alma-staging1:/opt/bibdata/current$ bundle exec rails c`

       - `DumpFile.where(dump_id: 6248)` you should be able to see in path: attribute the `incremental_36489280620006421_20240423_130418[009]_new.tar.gz`.









