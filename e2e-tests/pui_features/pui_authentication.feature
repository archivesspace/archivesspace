Feature: PUI Authentication

  Scenario: The PUI is open to the public when authentication is not required
     When an anonymous visitor visits the PUI
     Then the welcome page is displayed

  @pui_auth_enabled
  Scenario: The PUI requires sign-in when authentication is required
     When an anonymous visitor visits the PUI
     Then the login page is displayed

  @pui_auth_enabled
  Scenario: A staff member with PUI viewer permission is silently signed in to the PUI
    Given an administrator user is logged in
     When the user visits the PUI
     Then the user is signed in to the PUI as "admin"

  @pui_auth_enabled
  Scenario: A staff member without PUI viewer permission is not silently signed in to the PUI
    Given an archivist user is logged in
     When the user visits the PUI
     Then the login page is displayed

  @pui_auth_enabled
  Scenario: A user can log in directly on the PUI with valid credentials
     When an administrator logs in directly on the PUI
     Then the user is signed in to the PUI as "admin"

  @pui_auth_enabled
  Scenario: A user without PUI viewer permission is denied a direct PUI login
    Given a user without PUI viewer permission exists
     When that user logs in directly on the PUI
     Then the PUI permission denied message is displayed

  @pui_auth_enabled
  Scenario: A signed-in PUI user can log out
    Given an administrator user is logged in
      And the user visits the PUI
     When the user logs out of the PUI
     Then the login page is displayed
