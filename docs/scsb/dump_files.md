### Fetch and process the SCSB files into dump files

SSH to a bibdata machine as deploy user (Find a worker machine in your [environment](https://github.com/pulibrary/bibdata/tree/main/config/deploy)).
```
$ tmux attach-session -t full-index
$ cd /opt/bibdata/current
$ bundle exec rake scsb:import:full
CTRL+b d (to detach from tmux)
```
This kicks off an import job which will return immediately.  This can be monitored in [sidekiq busy queue](https://bibdata.princeton.edu/sidekiq/busy) or [sidekiq waiting queue](https://bibdata.princeton.edu/sidekiq/queues/default)

Takes 11-12 hours to complete. As they download and unpack they will be placed
in `/tmp/updates/` and as they are processed they will be moved to `/data/bibdata_files/scsb_update_files/`; you can follow the progress by listing the files in these directories.  You can also find the most recent Full Partner ReCAP Records from [the events page](https://bibdata.princeton.edu/events), and look at the dump files in its json.  Be sure not to deploy bibdata in the middle of this job, or else the job will have to start all over again from the beginning.

### Workflow
#### Full workflow
The `Import::Partners::Full` job kicks off the `StartWorkflowJob`, which creates an Event and a Dump, and sets off an individual workflow for each institution.

For each institution (Harvard University Libraries, Columbia University Libraries, New York Public Library), we download the Zip file from the SCSB Amazon S3 bucket, unzip the files, and then process each individual XML file from the big Zip file we downloaded. That individual XML file processing is detailed in the next section.

Once all of the unzipped files are finished being processed, we unlink the downloaded Zip file, then mark the overall Event as successful and finished, and set the Dump generated date.

```mermaid
---
title: Full Partner Import Workflow
---
graph LR;
    A[Full - Creates event and batch]-->B[StartWorkflowJob];
    B --> NN[Validate metadata CSV-HUL] & OO[Validate metadata CSV-CUL] & PP[Validate metadata CSV-NYPL];
    NN --> C[Download-HUL];
    OO --> D[Download-CUL];
    PP --> E[Download-NYPL];
    C --> F[Unzip-HUL];
    D --> G[Unzip-CUL];
    E --> H[Unzip-NYPL];
    F --> I[Process HUL XML A - see chart below for details];
    F --> J[Process HUL XML B, etc.];
    G --> K[Process CUL XML A];
    G --> L[Process CUL XML B, etc.];
    H --> M[Process NYPL XML A];
    H --> N[Process NYPL XML B, etc.];
    I --> DD[Unlink original XML file]
    DD --> JJ[Unlink original big zip file]
    J --> EE[Unlink original XML file]
    EE --> JJ[Unlink original big zip file]
    K --> FF[Unlink original XML file]
    FF --> KK[Unlink original big zip file]
    L --> GG[Unlink original XML file]
    GG --> KK[Unlink original big zip file]
    M --> HH[Unlink original XML file]
    HH --> LL[Unlink original big zip file]
    N --> II[Unlink original XML file]
    II --> LL[Unlink original big zip file]
    JJ --> MM[Mark Event successful and finished, set Dump generated date]
    KK --> MM
    LL --> MM
```

#### Individual file processing workflow
For each individual XML file from the large zip file described in the section above, we create a MARC::XMLReader object using the XML file, run a series of fixes on each record in the XML file, then write the cleaned Marc records to a new XML file. We then zip the new XML file, and attach the zipped zml file to a new DumpFile object, which is attached to the Dump for the overall Event. Finally, we unlink the original XML file.
```mermaid
---
title: Individual XML file processing workflow
---
graph LR;
  A[Create MarcXML object for full XML file] --> B[Clean up Marc - utf8 fixes, etc.]
  B --> C[Write cleaned Marc to new XML file]
  C --> D[Zip new XML file]
  D --> E[Create new DumpFile object and attach zipped XML to DumpFile]
  E --> F[Attach DumpFile to Dump]
  F --> G[Unlink original XML file]
```
