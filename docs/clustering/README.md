```mermaid
sequenceDiagram
    accTitle: Full Indexing using a clustered data set
    accDescr {
        Indexing process including clustering.
    }
    actor Developer
    Developer-->Bibdata: Run the cluster:build:full task
    Bibdata->>SCSB: Requests a dump of each partner's records via the SCSB API
    SCSB->>S3 Bucket: Creates dump files and uploads them to S3
    Bibdata->>S3 Bucket: Downloads files from S3
    Bibdata->>Bibdata: Creates a new event for the files using the date in the filename as the `generated_date`
    Bibdata->>ClusterManager: Request clustered data set combining both Alma data from last full dump and new SCSB full dump event just concluded
    ClusterManager->>Bibdata: write new filesets with cluster information added to the data
    Bibdata->>Bibdata: Create new event to store the created clustered data set
    Developer->>Bibdata: Runs the cluster:index:full task
    Bibdata->>Solr: Indexes the full dump event with cluster data`

```

Alternative Process using Reservoir

```mermaid
sequenceDiagram
    accTitle: Full Indexing using a clustered data set managed by Reservoir
    accDescr {
        Indexing process including clustering.
    }
    actor Developer
    Developer-->Bibdata: Run the cluster:build:full task
    Bibdata->>SCSB: Requests a dump of each partner's records via the SCSB API
    SCSB->>S3 Bucket: Creates dump files and uploads them to S3
    Bibdata->>S3 Bucket: Downloads files from S3
    Bibdata->>Bibdata: Creates a new event for the files using the date in the filename as the `generated_date`
    Bibdata->>Reservoir: Transfer and process all Alma marc file data from last full Alma dump into clusters
    Bibdata->>Reservoir: Trasnfer and process all SCSB marc file data into clusters
    Developer->>Bibdata: Runs the cluster:index:full task
    Bibdata->>Reservoir: Harvest full data set of clustered Marc Set via OAI-PMH
    Bibdata->>Sor: Index full data set

```

Another idea: A proxy server in front of solr

```mermaid
sequenceDiagram
    accTitle: Full Indexing using a proxy server in front of solr
    accDescr {
        Indexing process including clustering.
    }
    actor Developer
    Bibdata->>SCSB: Requests a dump of each partner's records via the SCSB API
    SCSB->>S3 Bucket: Creates dump files and uploads them to S3
    Bibdata->>S3 Bucket: Downloads files from S3
    Bibdata->>Proxy: Index the data as usual, sending the JSON we would ordinarily send to Solr to this Proxy instead
    Proxy->>Postgres: Calculate match keys, pairwise similarities, etc.  Store them in a database
    Bibdata->>Proxy: Commit!
    Proxy->>Solr: Send the batch of clustered records for indexing

```


Indexing Pipeline

```mermaid
sequenceDiagram
    accTitle: Indexing Pipeline
    accDescr {
        Proxy server workflow - Indexing Pipeline
    }
    actor Developer
    Bibdata->>Proxy: Incoming Solr formatted Json
    Proxy->>Postgres: Store Solr Json in solr_document table
    Bibdata->>Proxy: Commit!
    Proxy->>Proxy: Calculate match keys 
    Proxy->>Proxy: pairwise similarities 
    Proxy->>Proxy: create primary cluster record
    Proxy->>Proxy: enhance primary cluster record with data from other cluster members
    Proxy->>Solr: Send the batch of clustered records for indexing

```



Yet another idea: all data processing in the same system

For full dump, bibdata would still be responsible for making sure that Alma records are downloaded to the shared mounted disk.  Then...

```mermaid
sequenceDiagram
    actor Developer
    participant CatalogProcess
    participant Postgres

    Developer->>CatalogProcess: Request a full reindex
    CatalogProcess->>Shared Disk: Get alma and SCSB full dumps (MARCXML) from mount
    CatalogProcess->>Postgres: Store MARC in marc_document table
    Postgres->>Postgres: Add a "block" field that is indexed
    loop Within each block
      CatalogProcess->>CatalogProcess: pairwise similarities to determine clusters
    end
    loop For each cluster
      CatalogProcess->>Postgres: Check if any of the records in the cluster already have a UUID
      alt there is not a uuid yet
        CatalogProcess->>CatalogProcess: Create a new UUID
        CatalogProcess->>Postgres: Record the UUID and the records in it
      else there is a uuid already
        CatalogProcess->>Postgres: Update the UUID + record list
      end
      CatalogProcess->>CatalogProcess: Determine primary cluster record
      CatalogProcess->>CatalogProcess: Convert to JSON
      CatalogProcess->>CatalogProcess: Enhance JSON with data from other cluster members
    end
    CatalogProcess->>Solr: Index clustered records
    CatalogProcess->>Solr: Index Theses, Ephemera, Coins
```

For incremental:

```mermaid
sequenceDiagram
    actor Developer
    participant CatalogProcess
    participant Postgres

    CatalogProcess->>Shared Disk: Get incremental file
    CatalogProcess->>Postgres: Store MARC in marc_document table
    loop For each record
        Postgres->>Postgres: Determine the "block" for the record
        CatalogProcess->>CatalogProcess: pairwise similarities with other members of the block to determine its cluster
    end
    loop For each affected cluster
      CatalogProcess->>CatalogProcess: Create a changeset to Create, Update, or Delete a cluster
      alt Create or Update changeset
        CatalogProcess->>Postgres: Check if any of the records in the cluster already have a UUID
        alt there is not a uuid yet
            CatalogProcess->>CatalogProcess: Create a new UUID
            CatalogProcess->>Postgres: Record the UUID and the records in it
        else there is a uuid already
            CatalogProcess->>Postgres: Update the UUID + record list
        end
        CatalogProcess->>CatalogProcess: Determine primary cluster record
        CatalogProcess->>CatalogProcess: Convert to JSON
        CatalogProcess->>CatalogProcess: Enhance JSON with data from other cluster members
      end
    end
    CatalogProcess->>Solr: Apply changeset
```
