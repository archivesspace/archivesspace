Feature: User Create
  Background:
    Given an administrator user is logged in
  Scenario: User is created
     When the user clicks on 'System'
      And the user clicks on 'Manage Users'
      And the user clicks on 'Create User'
      And the user fills in 'Username'
      And the user fills in 'Full name'
      And the user fills in 'Password'
      And the user fills in 'Confirm password'
      And the user clicks on 'Create Account'
     Then the 'User' created message is displayed
  Scenario: User is not created because required fields are missing
     When the user clicks on 'System'
      And the user clicks on 'Manage Users'
      And the user clicks on 'Create User'
      And the user clicks on 'Create Account'
     Then the following error messages are displayed
       | Username - can't be empty |
       | Full name - Property is required but was missing |
       | Password - can't be empty |
       | Confirm password - can't be empty |
       | User not created |
