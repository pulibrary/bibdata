# Date of cataloging
Date: 2020-08-17
## Status
Accepted
## Context
The need is to identify newly available materials in a facet.
## Decision
* If the item is an electronic resource, capture the date of the bib's creation.
* If the item is a physical resource, capture the date of the earliest item's creation; return nil if there are no items.
* https://github.com/pulibrary/voyager_helpers/blob/37b62ad83ed2f1af6185e54534d901e23e5fdf30/lib/voyager_helpers/liberator.rb#L959
## Consequences
Users are able to search for newly processed items.