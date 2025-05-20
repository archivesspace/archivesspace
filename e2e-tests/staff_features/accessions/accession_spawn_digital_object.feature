Feature: Accession spawn Digital Object
  Background:
    Given an administrator user is logged in
      And the "Spawn description for Digital Object instances from linked record" setting is enabled in the Repository Preferences
      And an Accession has been created
      And the Accession is opened in edit mode
  Scenario: Digital Object form is prefilled with Accession data
     When the user clicks on "Add Digital Object" in the "Instances" form
      And the user clicks on the first dropdown in the "Instances" form
      And the user clicks on "Create" in the dropdown menu in the "Instances" form
     Then the Create Digital Object modal is displayed
      And the Digital Object title is filled in with the Accession Title
      And the following Digital Object forms have the same values as the Accession
       | Languages  |
       | Dates      |
