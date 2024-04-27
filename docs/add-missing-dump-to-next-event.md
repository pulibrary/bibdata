To Add a dump that was skipped for any reason you must first find the event you would like to add it to.  This is generally the next Event that occurred after the error.  This can be found by hovering over the event in the bibdata ui.

In our case the event id is 1104, so we will utilize this number in our example.  The procedure is to create new files for your missed dumps and then create new files for the original dumps so that the files will be retrieved in the correct order by active record.

Next gather the path(s) of the dump files that were not processed and store those in missing_dump_files

After that the rest of the code is fixed and should work to add the files into the dump.

```
event_id = 1104
missing_dump_files = ["/data/marc_liberation_files/incremental_16931978440006421_20220314_110330[029]_new.tar.gz",
                      "/data/marc_liberation_files/incremental_16935925020006421_20220314_140320[055]_delete.tar.gz",
                      "/data/marc_liberation_files/incremental_16935925020006421_20220314_140320[055]_new.tar.gz"]
dump = Dump.find(event_id)
original_files  = dump.dump_files
original_files.each {|file| file.dump_id = nil; file.save}
missing_dump_files.each do |missing|
  DumpFile.create(dump_file_type: :updated_records, path: missing, dump_id: dump.id)
end

original_files.each do |file|
  DumpFile.create(dump_file_type: file.dump_file_type, path: file.path, dump_id: dump.id)
end
dump.reload
dump.dump_files
```
