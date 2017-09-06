# Indexing with Docker Notes

## Pull latest recap image
```sudo docker pull pulibrary/orangeindex:recap```
## Confirm status of image
```sudo docker images```
## Use Docker to index a single file
```sudo docker run -v /my-system-path/sample_marc_directory:/tmp pulibrary/orangeindex:recap bash -c 'rake index SET_URL=http://lib-solr2.princeton.edu:8983/solr/blacklight-core-recap MARC=/tmp/my_sample.xml; true'```
## Use Docker to index a directory of marc xml files
```sudo docker run -idt -v /my-systems-path/marc_xml_data:/tmp pulibrary/orangeindex bash -c 'rake index_folder SET_URL=http://lib-solr2.princeton.edu:8983/solr/blacklight-core-recap MARC_PATH=/tmp' >> /tmp/bulk_import.log 2>&1
```
## View solr config console via SSH Tunnel
```ssh -L 9000:localhost:8983 systems@lib-solr2```
```http://localhost:9000/solr/```
## Run a full re-index of pul marc data against an arbitrary solr core (with sudo privs)
```docker run -v /tmp:/tmp -e SET_URL=http://lib-solr2.princeton.edu:8983/solr/blacklight-core-recap --net=host pulibrary/orangeindex bash -c 'rake liberate:full' >> /tmp/recap.log 2>&1```

## Building the Browse index
* ```rake browse:all```
* ```rake load:all```

## Cron tasks
10 01 * * * /bin/bash -c 'export PATH="$HOME/.rbenv/bin:$PATH" && eval "$(rbenv init -)" && cd /opt/orangelight && PATH=$PATH:/usr/local/bin SOLR_URL=http://lib-solr2.princeton.edu:8983/solr/blacklight-core-recap rake$
00 02 * * * /bin/bash -c 'export PATH="$HOME/.rbenv/bin:$PATH" && eval "$(rbenv init -)" && cd /opt/orangelight && PATH=$PATH:/usr/local/bin SOLR_URL=http://lib-solr2.princeton.edu:8983/solr/blacklight-core-recap rake$
