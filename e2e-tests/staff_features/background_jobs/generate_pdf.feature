Feature: Generate PDF Job
  Background:
    Given an administrator user is logged in
      And a Resource has been created
  Scenario: Generate PDF Job can be created
    Given the user is on the 'Generate PDF' background job page
      And the user fills in and selects the Resource from the search field
      And the user checks 'Include Unpublished'
      And the user clicks on 'Start Job'
     Then the 'print_to_pdf_job' page is displayed
      And the job completes
      And the user clicks on 'Refresh Page'
      And the user clicks on 'Download PDF'
      And a PDF file is downloaded for the resource
