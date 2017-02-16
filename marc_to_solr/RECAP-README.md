# Recap Test Indexing

## Pull latest recap image
```sudo docker pull pulibrary/orangeindex:recap```
## Confirm status of image
```sudo docker images```
## Use Docker to install a file
```sudo docker run -v /my-system-path/sample_marc_directory:/tmp pulibrary/orangeindex:recap bash -c 'rake index SET_URL=http://lib-solr2.princeton.edu:8983/solr/blacklight-core-recap MARC=/tmp/my_sample.xml; true'```