Feature: Digital Object Event Create
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
      And the Digital Object is opened in edit mode
  Scenario: Digital Object Event create page
     When the user clicks on 'Add Event'
      And the user clicks on 'Add Event' in the dropdown menu
     Then the New Event page is displayed with the Digital Object linked
  Scenario: Digital Object Event is created
    Given the New Event page is open for a Digital Object
     When the user selects 'Single' from 'Type' in the 'Event Date/Time' form
      And the user fills in 'Begin' with '2020-01-01' in the 'Event Date/Time' form
      And the user links an Agent
      And the user clicks on 'Save'
     Then the 'Event' created message is displayed
  Scenario: Digital Object Event is not created due to missing required fields
    Given the New Event page is open for a Digital Object
     When the user selects 'Single' from 'Type' in the 'Event Date/Time' form
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Expression - is required unless a begin or end date is given |
       | Begin - is required unless an expression or an end date is given |
       | Agents - Property is required but was missing |
       | Role - Property is required but was missing |
  Scenario: Digital Object Event is not created due to missing required fields, with Event Date/Time Expression filled in
    Given the New Event page is open for a Digital Object
     When the user selects 'Single' from 'Type' in the 'Event Date/Time' form
      And the user fills in 'Expression' with 'Date Expression' in the 'Event Date/Time' form
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Agents - Property is required but was missing |
       | Role - Property is required but was missing |
  Scenario: Digital Object Event is not created due to invalid date
    Given the New Event page is open for a Digital Object
     When the user selects 'Single' from 'Type' in the 'Event Date/Time' form
      And the user fills in 'Begin' with '2020-22-22' in the 'Event Date/Time' form
      And the user links an Agent
      And the user clicks on 'Save'
     Then only the following error message is displayed
       | Begin - Not a valid date |
