Feature: Resource Unpublish
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Unpublish the Resource record from toolbar
     When the user clicks on 'Unpublish All'
      And the user clicks on 'Unpublish All' in the modal
     Then the 'Resource' unpublished message is displayed
  Scenario: Unpublish the Resource record from the Publish checkbox in the Basic Information section
     When the user unchecks 'Publish'
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
