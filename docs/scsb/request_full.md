# Request partners full dump from SCSB

## Through the UI

Visit the [SCSB ReCAP](https://scsb.recaplib.org/) website.

In the homepage from the dropdown select 'Princeton'

### Example of a submission form to request a full dump from Columbia (CUL)

Do the following separately for each institution.

1. Select the tab 'Data export' -> Select the radio button 'Export data dump'

2. Field: Collection group ids

    Description: Data can be requested by Collection Group ID, either Shared (use 1) or Open (use 2) or Private (use 3) or Committed (use 5) or Uncommittable (use 6). Default is Shared and Open, can use 1,2,3,5,6 as well.
    
    Input value: 1,2,5,6

3. Field: Date

    Description: Get updates to middleware collection since the date provided. Date format will be a string (yyyy-MM-dd HH:mm) and is Eastern Time.
    
    Input value: Leave-blank-for-full-dump

4. Field: Email To Address

    Description: Email address to whom email will be sent upon completion
    
    Input value: your-email-address

5. Field: Fetch Type
    
    Description: Type of export - Incremental (use 1) or Deleted (use 2) or Full Dump (use 10)
    
    Input value: 10

6. Field: IMS (inventory management system) Depository Codes: 
    
    Description: Ims depository - RECAP (use RECAP) or Harvard depository (use HD).Default is RECAP can use RECAP,HD as well
    
    Input value: RECAP,HD

7. Field: Institution codes 
    
    Description: Institution code(s) for requesting shared/open updates from partners: PUL = Princeton, CUL = Columbia, NYPL = New York Public Library, HL = Harvard Library
    
    Input value: CUL

8. Field: Output format
    
    Description: Type of format - Marc xml (use 0) or SCSB xml (use 1), for deleted records only json format (use 2)
    Input value: 0

9. Field: Requesting Institution Code
   
    Description: Institution codes of the requesting institution. PUL = Princeton, CUL = Columbia, NYPL = New York Public Library, HL = Harvard Library
    
    Input value: PUL

10. Field: Transmission Type
    
    Description: Type of transmission - for S3 use 0, for HTTP response use 1. Default is S3.
    
    Input value: 0

11. Submit the form 'Click on Start export Data Dump'
