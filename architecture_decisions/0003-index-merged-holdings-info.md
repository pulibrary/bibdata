# Merging holdings information for indexing
Date: 2020-08-17
## Status
Accepted
## Context
To speed up indexing we need holdings information included in the dump.
## Decision
* Removes bib 852s and 86Xs, adds 852s, 856s, and 86Xs from holdings, adds 959 catalog date
* https://github.com/pulibrary/voyager_helpers/blob/37b62ad83ed2f1af6185e54534d901e23e5fdf30/lib/voyager_helpers/liberator.rb#L940
## Consequences
Holdings information does not need to be looked up in real-time for record display.