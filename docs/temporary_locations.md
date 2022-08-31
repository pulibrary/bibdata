Temporary locations:

## Case 1:  
An item is moved in a temporary location "lewis$res". The JS availability response for this item would be https://bibdata.princeton.edu/bibliographic/availability.json?deep=true&bib_ids=99125557856006421: 
```
{
  "99125557856006421": {
    "lewis$res": {
      "on_reserve": "Y",
      "location": "lewis$res",
      "label": "Lewis Library - Course Reserve",
      "status_label": "Available",
      "copy_number": null,
      "cdl": false,
      "temp_location": true,
      "id": "lewis$res"
    }
  }
}
```
In the 'holdings_1display' field we include the temp_location_code. The holdings_1display for this record would be:
```
"holdings_1display": "{\"lewis$res\":{\"location_code\":\"lewis$res\",\"current_location\":\"Course Reserve\",\"current_library\":\"Lewis Library\",\"call_number\":\"QD411 .S65 2016\",\"call_number_browse\":\"QD411 .S65 2016\",\"temp_location_code\":\"lewis$res\",\"items\":[{\"holding_id\":\"22939748930006421\",\"id\":\"23939748920006421\",\"status_at_load\":\"1\",\"barcode\":\"32101108937986\",\"copy_number\":\"1\"},{\"holding_id\":\"22939748930006421\",\"id\":\"23939748880006421\",\"status_at_load\":\"1\",\"barcode\":\"32101108937994\",\"copy_number\":\"2\"}]}}"
```
When the current location 'lewis$res' of a holding is different from the permanent location 'lewis$stacks' then we have a temporary location.  
We index the holdings with their items in the field 'holdings_1display'. The holding id for the temporary location 'lewis$res' is the exact location code 'lewis$res'.  
The items that are part of this temporary location reference the permanent holding id. This item/holding id is used in the Orangelight UI/request button to load the request form when it is a temporary location holding but not 'RES_SHARE$IN_RS_REQ'.  
The holding id for each item is the permanent location holding id '22939748930006421'. To make this more clear see the specific marc xml record and compare `852|8 with 876|0` also `852|b $ 852|c with 876|y $ 876|z`: 
```
<datafield tag="852" ind1="0" ind2=" ">
    <subfield code="b">lewis</subfield>
    <subfield code="c">stacks</subfield>
    <subfield code="h">QD411</subfield>
    <subfield code="i">.S65 2016</subfield>
    <subfield code="8">22939748930006421</subfield>
</datafield>
<datafield tag="876" ind1=" " ind2=" ">
    <subfield code="0">22939748930006421</subfield>
    <subfield code="a">23939748920006421</subfield>
    <subfield code="j">1</subfield>
    <subfield code="z">res</subfield>
    <subfield code="d">2022-08-16</subfield>
    <subfield code="p">32101108937986</subfield>
    <subfield code="t">1</subfield>
    <subfield code="y">lewis</subfield>
</datafield>
<datafield tag="876" ind1=" " ind2=" ">
    <subfield code="0">22939748930006421</subfield>
    <subfield code="a">23939748880006421</subfield>
    <subfield code="j">1</subfield>
    <subfield code="z">res</subfield>
    <subfield code="d">2022-08-16</subfield>
    <subfield code="p">32101108937994</subfield>
    <subfield code="t">2</subfield>
    <subfield code="y">lewis</subfield>
</datafield>
```
In Orangelight in order to display the status we match the holding_id from the availability response with the holding id (hash key) from the indexed 'holdings_1display' field.  

Currently if a staff member moves an item from a temporary location to a permanent location or the opposite, the new record will not get indexed immediately. See schedule for incremental indexing https://github.com/pulibrary/bibdata/blob/main/docs/alma_publishing_jobs_schedule.md. This results in a mismatch between the holding id in the JS availability response that Orangelight receives from bibdata and the indexed 'holdings_1display' holding id (hash key). Finally this results in an empty availability status in the record page. This is fixed with the next incremental job.

## Case 2: 

Temporary location "RES_SHARE$IN_RS_REQ". This is a **unique** temporary location case.
When an item is moved to this specific temporary location we index it as a permanent location. The JS availability for this item would be: https://bibdata.princeton.edu/bibliographic/availability.json?deep=true&bib_ids=995217553506421 
```
{
  "995217553506421": {
    "RES_SHARE$IN_RS_REQ": {
      "on_reserve": "N",
      "location": "RES_SHARE$IN_RS_REQ",
      "label": "Resource Sharing Library - Lending Resource Sharing Requests",
      "status_label": "Unavailable",
      "copy_number": null,
      "cdl": false,
      "temp_location": true,
      "id": "RES_SHARE$IN_RS_REQ"
    }
  }
}
```
The specific "RES_SHARE$IN_RS_REQ" location is indexed in 'holdings_1display' field as permanent. We include the temp_location_code:
```
"holdings_1display": "{\"22622715900006421\":{\"location_code\":\"firestone$stacks\",\"location\":\"Stacks\",\"library\":\"Firestone Library\",\"call_number\":\"LA791.3 .G74 1989\",\"call_number_browse\":\"LA791.3 .G74 1989\",\"temp_location_code\":\"RES_SHARE$IN_RS_REQ\",\"items\":[{\"holding_id\":\"22622715900006421\",\"id\":\"23622715890006421\",\"status_at_load\":\"0\",\"barcode\":\"32101017236959\",\"copy_number\":\"1\"}]}}"
```

See the specific marc xml record and compare `852|8 with 876|0` and `852|b $ 852|c with 876|y $ 876|z` 
```
<datafield tag="852" ind1="0" ind2="0">
    <subfield code="b">firestone</subfield>
    <subfield code="c">stacks</subfield>
    <subfield code="h">LA791.3</subfield>
    <subfield code="i">.G74 1989</subfield>
    <subfield code="8">22622715900006421</subfield>
</datafield>
<datafield tag="876" ind1=" " ind2=" ">
    <subfield code="0">22622715900006421</subfield>
    <subfield code="a">23622715890006421</subfield>
    <subfield code="j">0</subfield>
    <subfield code="z">IN_RS_REQ</subfield>
    <subfield code="d">2000-06-13 06:59:00</subfield>
    <subfield code="p">32101017236959</subfield>
    <subfield code="t">1</subfield>
    <subfield code="y">RES_SHARE</subfield>
</datafield>
```
In this case, in Orangelight, in order to display the status we match the holding id from the JS availability response with the indexed holdings_1display["temp_location_code"].  

When a staff member moves an item from this temporary location to a permanent location the availability status will still display, because the holding id in the JS availability response matches the indexed holding id in the holdings_1display.

When a staff member moves an item from a permanent location to this temporary location then there is a mismatch between the JS availability response and the not indexed yet holdings_1display["temp_location_code"]. The holdings_1display["temp_location_code"] is used from Orangelight in order to display the status in the specific temporary location "RES_SHARE$IN_RS_REQ". Finally this results in an empty availability status in the record page. This is fixed with the next incremental job.