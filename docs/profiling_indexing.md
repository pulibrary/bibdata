### Profiling performance of indexing

Profiling can be useful for:
* Identifying bottlenecks that slow down indexing
* Checking whether a particular change has helped with that specific bottleneck

#### Profiling with ruby-prof

1. Download a large (at least 10,000 records) MarcXML file.  In this example, we will use the filename big_marc.xml
1. `bundle exec rake servers:start`
2. `bundle add ruby-prof`
3. `lando info` and find the development solr's external_connection port.  In this example, we will use port 55555.
4. Run `bundle exec ruby-prof $(bundle show traject)/bin/traject -- -c marc_to_solr/lib/traject_config.rb big_marc.xml -u http://localhost:55555/solr/bibdata-core-development`

#### Interpreting the results

* This gives a list of methods that were called, how many times they were called, how much time was spent on each method, and how much time was spent on child methods.
* There are multiple reports, one for each Thread.  The most salient report is usually at the top of the output, but not always.
* The most time-consuming methods (i.e. likely bottlenecks) will be at the top of the report.  It could be a method that is slow every time, or it could be a fast method that is called an excessive number of times.
