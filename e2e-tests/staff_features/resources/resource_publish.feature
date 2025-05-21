Feature: Resource Publish
  Background:
    Given an administrator user is logged in
      And a Resource has been created
  Scenario: Publish the Resource record from toolbar
    Given the Resource is opened in edit mode
     When the user clicks on 'Publish All'
      And the user clicks on 'Publish All' in the modal
     Then the 'Resource' published message is displayed
      And the 'View Published' button is displayed
  Scenario: Publish the Resource record from the Publish checkbox in the Basic Information section
    Given the Resource is opened in edit mode
     When the user checks 'Publish'
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
      And the 'View Published' button is displayed
  Scenario: View a published Resource Record in the public interface
    Given the Resource is opened in edit mode
      And the Resource is published
     When the user clicks on 'View Published'
     Then the Resource opens on a new tab in the public interface
