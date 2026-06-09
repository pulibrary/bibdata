### Profiling performance of indexing

Profiling can be useful for identifying bottlenecks that slow down indexing.

It is not so useful for validating whether your change actually helped the situation, a benchmark is a better tool for that

#### Profiling with ruby-prof

1. Download a large (at least 10,000 records) MarcXML file.  In this example, we will use the filename big_marc.xml
1. `bundle exec rake servers:start`
2. `bundle add vernier`
3. `lando info` and find the development solr's external_connection port (we will use port 55555 in this example) and the redis external_connection port (we will use 44444).
4. If you have not yet cached figgy data in redis, run `BIBDATA_REDIS_PORT=44444 CATALOG_SYNC_TOKEN=[get this from the box] FIGGY_URL=https://figgy.princeton.edu cargo run --bin cache_figgy_data`
5. Run `BIBDATA_REDIS_PORT=44444 be vernier run -- traject -c marc_to_solr/lib/traject_config.rb big_marc.xml -u http://localhost:55555/solr/bibdata-core-development`

#### Interpreting the results

* Go to https://vernier.prof/ and upload your file
* Select the thread that did most of the indexing work (usually the first `worker-1` thread)
* To find the methods where we spent the most time, on the Call Tree tab, make sure that Invert Call Stack is checked
* The flame graph tab can been useful.  I like to right click on a particular area of interest and choose "Focus on subtree".
