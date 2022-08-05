### Workflow to update Augment the Subject
1. A request will come from the metadata librarians or catalogers, either via a Github ticket or through Slack
1. They will provide you with a link to a Google Sheets document
    * Ensure that everyone on the team who will need access to the sheet can at least view it
    * The document should include:
        * A sheet with the LC vocabulary, which needs to include the headers "With subdivisions ǂx etc." and "Term in MARC". This sheet should include *all* LC vocabulary for Augment the Subject, not just new vocabulary
        * A sheet with additional subfields (currently only subfield x)
1. Download the LC vocabulary sheet as a CSV file (currently File-->Download-->Comma Separated Values (.csv))
1. In your local development environment:
    * Replace the file currently at `marc_to_solr/lib/augment_the_subject/indigenous_studies.csv` with the newly downloaded file, using the same name. Again, ensure that the headings "With subdivisions ǂx etc." and "Term in MARC" have not changed. 
    * Run the rake task to create a new version of the fixture files: `bundle exec rake augment:recreate_fixtures`
    * Look at the differences in the `marc_to_solr/lib/augment_the_subject/indigenous_studies_required.json` and `marc_to_solr/lib/augment_the_subject/standalone_subfield_a.json` and make sure the structure has remained the same and they appear like reasonable changes, based on the changes to the csv (for example, similar number of added subjects, not too many subjects removed, appear to be utf-8)
    * Look at the "Additional subfields" sheet and visually compare it to `marc_to_solr/lib/augment_the_subject/standalone_subfield_x.json`. , add or remove any to make the list in the json match the sheet. Currently there are only 10 subfields listed, so this should not be difficult, but if this list grows significantly we may want to automate this process.
    * Run the rspec tests tagged "indexing" `bundle exec rspec --tag indexing`
        * If there are failing tests, work to get them passing 
    * On a branch, commit the changes resulting from these steps and open a pull request
1. Deploy the branch to bibdata-staging, and test according to the practices in the test_indexing.md file. 