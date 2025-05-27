Feature: Digital Object Publish
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
  Scenario: Publish the Digital Object from toolbar
    Given the Digital Object is opened in edit mode
     When the user clicks on 'Publish All'
      And the user clicks on 'Publish All' in the modal
     Then the 'Digital Object' published message is displayed
      And the 'View Published' button is displayed
  Scenario: Publish the Digital Object from the Publish checkbox in the Basic Information section
    Given the Digital Object is opened in edit mode
     When the user checks 'Publish'
      And the user clicks on 'Save'
     Then the 'Digital Object' updated message is displayed
      And the 'View Published' button is displayed
  Scenario: View a published Digital Object in the public interface
    Given the Digital Object is opened in edit mode
      And the Digital Object is published
     When the user clicks on 'View Published'
     Then the Digital Object opens on a new tab in the public interface
