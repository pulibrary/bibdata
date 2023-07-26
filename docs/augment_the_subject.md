### Workflow to update Augment the Subject
1. A request will come from the metadata librarians or catalogers, either via a Github ticket or through Slack
1. They will provide you with a link to a Google Sheets document
    * Ensure that everyone on the team who will need access to the sheet can at least view it
    * The document should include two sheets:
        1. A sheet with the LC vocabulary.  This sheet should include *all* LC vocabulary for Augment the Subject, not just new vocabulary.  The sheet needs to include the headers:
            1. "Term"
            1. "With subdivisions ǂx etc."
            1. "Tag"
            1. "Left match bib field"
            1. "Term in MARC".
        1. A sheet with additional subfields (currently only subfield x)
1. Download the LC vocabulary sheet as a CSV file (currently File → Download → Comma Separated Values (.csv))
1. Rename the file to `indigenous_studies.csv`.
1. In your local development environment:
    * Replace the file currently at `marc_to_solr/lib/augment_the_subject/indigenous_studies.csv` with the newly downloaded file. Again, ensure that the headings "With subdivisions ǂx etc." and "Term in MARC" have not changed. 
    * Run the rake task to create a new version of the fixture files: `bundle exec rake augment:recreate_fixtures`
    * Confirm that `indigenous_studies_required.json` and `standalone_subfield_a.json` are valid json files.
    * Format the `indigenous_studies_required.json` and `standalone_subfield_a.json` files. In VS Code, you can press Shift + Option + F.
    * Using the VS Code source control tool, look at the differences in the `marc_to_solr/lib/augment_the_subject/indigenous_studies_required.json` and `marc_to_solr/lib/augment_the_subject/standalone_subfield_a.json` and make sure the structure has remained the same and they appear like reasonable changes, based on the changes to the csv (for example, similar number of added subjects, not too many subjects removed, appear to be utf-8)
    * Look at the "Additional subfields" tab in the spreadsheet and visually compare it to `marc_to_solr/lib/augment_the_subject/standalone_subfield_x.json`. This file is not touched by the rake task, so you will have to edit it manually.  Add or remove any to make the list in the json match the sheet. If this list grows significantly we may want to automate this process.
    * Run the rspec tests tagged "indexing" `bundle exec rspec --tag indexing`
        * If there are failing tests, work to get them passing 
    * On a branch, commit the changes resulting from these steps and open a pull request
1. Deploy the branch to bibdata-staging, and test according to the practices in the test_indexing.md file. 
