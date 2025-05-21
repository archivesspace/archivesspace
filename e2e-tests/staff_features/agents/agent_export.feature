Feature: Agent Export
  Background:
    Given an administrator user is logged in
      And an Agent has been created
      And the Agent is opened in edit mode
  Scenario: Agent Download EAC-CPF
     When the user clicks on 'Download EAC-CPF'
     Then an EAC-CPF XML file is downloaded
  Scenario: Agent Download MARCXML AUTHORITY
     When the user clicks on 'Download MARCXML Authority'
     Then a MARC XML file is downloaded
