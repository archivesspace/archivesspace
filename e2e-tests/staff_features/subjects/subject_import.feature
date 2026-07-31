Feature: Subject Import with the LCNAF Import Plug-In
  Background:
    Given an administrator user is logged in
  Scenario: Subject Import with the LCNAF Import Plug-In
     When the user clicks on the gear icon
      And the user hovers on 'Plug-ins' in the dropdown menu
      And the user clicks on 'LCNAF Import' in the dropdown menu
      And the user checks 'LCSH - https://id.loc.gov/authorities/subjects' in the LCNAF Import form
      And the user fills in 'Name or Subject' with 'subject heading'
      And the user clicks on 'Search'
      And the user selects the first LCNAF importer search result
      And the user clicks on 'Import'
     Then the 'Import Job' page is displayed
      And the job completes
      And the following message is displayed
        | The job has completed. |
      And the 'Subject headings' record is listed in the New & Modified Records form
