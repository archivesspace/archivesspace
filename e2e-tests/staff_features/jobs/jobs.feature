Feature: Jobs
  Background:
    Given an administrator user is logged in
  Scenario: Import location job can be created
     Given the user is on the Import Job page
      When the user selects 'Location CSV' from 'Import Type'
       And the user adds 'templates/aspace_location_import_template.csv' as a file
       And the user clicks on 'Start Job'
      Then the Import Job page is displayed
       And the job completes
       And the user clicks on 'Refresh Page'
       And the 'New & Modified Records' section is displayed
       And the New & Modified Records section contains 3 links
       And the record links do not display 'Record belongs to a different repository'
