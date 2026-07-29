Feature: Reports and suppressed records
  Background:
    Given an administrator user is logged in
  Scenario: Suppressed accessions are excluded from a report by default
    Given an Accession has been created
      And the Accession is opened in edit mode
      And the Accession is suppressed
      And the user is on the 'Create Report' background job page
      And the user selects the 'Accession Report' report
      And the user selects 'CSV' from 'Format'
      And the user clicks on 'Start Job'
     Then the 'report_job' page is displayed
      And the job completes
      And the user clicks on 'Refresh Page'
      And the user clicks on 'Download Report'
      And the downloaded report does not contain the Accession
  Scenario: Users who can view suppressed records can include them in a report
    Given an Accession has been created
      And the Accession is opened in edit mode
      And the Accession is suppressed
      And the user is on the 'Create Report' background job page
      And the user selects the 'Accession Report' report
      And the user checks 'Include suppressed records'
      And the user selects 'CSV' from 'Format'
      And the user clicks on 'Start Job'
     Then the 'report_job' page is displayed
      And the job completes
      And the user clicks on 'Refresh Page'
      And the user clicks on 'Download Report'
      And the downloaded report contains the Accession
  Scenario: The include suppressed option is enabled for users who can view suppressed records
    Given the user is on the 'Create Report' background job page
      And the user selects the 'Accession Report' report
     Then the 'Include suppressed records' field is enabled
  Scenario: The include suppressed option is disabled for users who cannot view suppressed records
    Given an archivist user is logged in
      And the user is on the 'Create Report' background job page
      And the user selects the 'Accession Report' report
     Then the 'Include suppressed records' field is disabled
