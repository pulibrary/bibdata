# Event with a dump and no files attached

Scenario: An Alma incremental or general publishing job (successful or not successful) ran but a connection error exists between libsftp_production (SFTP server) and Bibdata or libsftp_production and the Alma sandbox. As a result Bibdata will create an 'event' and a 'dump' with no dump files. 

* Connection error between Alma and libsftp_production 
  - No files will be transferred to libsftp_production. 
  - Bibdata will create an 'event' and a 'dump' with no dump files. 
  - The Event has 'Alma Job Status': 'Failed'.
  
  Next steps: Communicate with the Alma Tech and Operations team. Let them know that there is a connection error. When the connection error is fixed, the next Alma incremental or General publishing job is expected to run successfully.
  

* Connection error between Bibdata and libsftp_production

  - The Alma job is successful. 
  - Bibdata will create an 'event' and a 'dump' with no dump files.
  - The 'event' has 'Alma Job Status': 'COMPLETED_SUCCESS'
  - libsftp_production VM has the files from the Alma job. 
  - ssh as deploy or pulsys to [libsftp_production](https://github.com/pulibrary/princeton_ansible/blob/main/inventory/all_projects/lib_sftp) and confirm that the files exist in `/alma/publishing/`. The file name includes the alma JOB_ID.
  - Restart the bibdata SQS poller in the Bibdata worker VM (It runs in one of the two workers).
  Wait and see if the files are imported in Bibdata. Some times SQS poller needs a restart to poll the files and they will be imported in Bibdata.
  - If restarting the SQS poller service on the Bibdata worker machine doesn't resolve the issue then import the files through the rails console:
    - `ssh deploy@bibdata-worker-prod1`
    - `cd /opt/bibdata/current`
    - `RAILS_ENV=production bundle exec rails c`
    - Find the 'event' ID that has a 'dump' with no dump_files. Use the UI or the console. For example:
      - The event with id: '10650' has a 'dump' with no files. `Dump.find_by(event_id: 10650).dump_files` should return an [] array.
      - Find the job id from the event `message_body` attribute: `event_10650.message_body`.
      ```
      "{\"id\":\"40793653490006421\",\"action\":\"JOB_END\",\"institution\":{\"value\":\"01PRI_INST\",\"desc\":\"Princeton University Library\"},\"time\":\"2025-01-10T15:03:29.237Z\",\"job_instance\":{\"id\":\"40793653490006421\",\"name\":\"Publishing Platform Job Incremental Publishing\"
      ```
       In this case the job id is `40793653490006421`. 
      - Find the dump for this event: `dump = Dump.find_by(event_id: 10650)`
      - Use the correct [dump_file_type](https://github.com/pulibrary/bibdata/blob/main/config/alma.yml#L10-L15)  
        The file type that will be created when the files are attached will be either 'updated_records' or 'bib_records'. In this example the files were created from an Alma incremental job. The `dump_file_type` is 'updated_records'.
      - Import the files and attach them to the dump:
        ```
          Import::Alma::AlmaDownloader.files_for(job_id: '40793653490006421', dump_file_type: 'updated_records').each do |file|
            dump.dump_files << file
          end
        ```
      - Confirm that the files are attached:
        `dump.dump_files` should not return an empty array.