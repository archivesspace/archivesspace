Feature: Digital Object create Assessment
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
      And the Digital Object is opened in edit mode
  Scenario: Assessment form is prefilled with Digital Object title
     When the user clicks on 'More'
      And the user clicks on 'Create Assessment'
     Then the New Assessment page is displayed
      And the Assessment is linked to the Digital Object in the 'Basic Information' form
