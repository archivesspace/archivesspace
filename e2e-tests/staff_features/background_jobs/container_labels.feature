Feature: Container Labels
  Background:
    Given an administrator user is logged in
      And a Resource with an Archival Object and a Container Instances has been created
  Scenario: Run Container Labels background job
    Given the user is on the 'Container Labels' background job page
      And the user fills in and selects the Resource from the search field
      And the user clicks on 'Start Job'
     Then the 'container_labels_job' page is displayed
      And the job completes
      And the user clicks on 'Refresh Page'
      And the user clicks on 'File'
      And a TSV file is downloaded with the container labels for the resource
