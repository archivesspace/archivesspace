Feature: Resource Update Basic Information
  Background:
    Given an administrator user is logged in
      And a Resource has been created
  Scenario: Update basic information fields for a Resource
    Given the user is on the Resource edit page
     When the user selects 'Records' from "Resource Type"
      And the user checks 'Publish?'
      And the user checks 'Restrictions Apply?'
      And the user fills in 'Repository Processing Note' with 'VTF #3810'
      And the user clicks on 'Save Resource'
     Then the 'Resource' updated message is displayed
      And the 'Resource Type' has selected value 'Records'
      And the 'Publish?' is checked
      And the 'Restrictions Apply?' is checked
      And the 'Repository Processing Note' has value 'VTF #3810'
