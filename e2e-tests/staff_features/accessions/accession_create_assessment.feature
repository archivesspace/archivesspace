Feature: Accession create Assessment
  Background:
    Given an administrator user is logged in
      And an Accession has been created
      And the Accession is opened in edit mode
  Scenario: Assessment form is prefilled with Accession title
     When the user clicks on 'More'
      And the user clicks on 'Create Assessment'
     Then the New Assessment page is displayed
      And the Assessment is linked to the Accession in the 'Basic Information' form
