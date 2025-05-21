Feature: Resource create Assessment
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Assessment form is prefilled with Resource title
     When the user clicks on 'More'
      And the user clicks on 'Create Assessment'
     Then the New Assessment page is displayed
      And the Assessment is linked to the Resource in the 'Basic Information' form
