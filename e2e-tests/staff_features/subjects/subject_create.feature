Feature: Subject Create
  Background:
    Given an administrator user is logged in
  Scenario: Subject is created
    Given the user is on the New Subject page
     When the user selects 'Art & Architecture Thesaurus' from 'Source' in the 'Basic Information' form
      And the user fills in 'Term'
      And the user selects 'Topical' from 'Type' in the 'Terms and Subdivisions' form
      And the user clicks on 'Save'
     Then the 'Subject' created message is displayed
  Scenario: Subject is not created because required fields are missing
    Given the user is on the New Subject page
     When the user clicks on 'Save'
     Then the following error messages are displayed
       | Term - Property is required but was missing   |
       | Type - Property is required but was missing   |
       | Source - Property is required but was missing |
