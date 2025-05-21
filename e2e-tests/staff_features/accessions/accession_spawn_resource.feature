Feature: Accession Spawn Resource
  Background:
    Given an administrator user is logged in
      And an Accession has been created
      And the Accession is opened in edit mode
  Scenario: Resource form is prefilled with Accession data
     When the user clicks on 'Spawn'
      And the user clicks on 'Resource' in the spawn dropdown menu
     Then the New Resource page is displayed
      And the Resource has been spawned from Accession info message is displayed
      And the Resource is linked to the Accession in the Related Accessions form
      And the Resource title is filled in with the Accession Title
      And the Resource publish is set from the Accession publish
      And the Resource notes are set from the Accession Content Description and Condition Description
      And the following Resource forms have the same values as the Accession
        | Agent Links                  |
        | Related Accessions           |
        | Subjects                     |
        | Languages                    |
        | Dates                        |
        | Extents                      |
        | Rights Statements            |
        | Metadata Rights Declarations |
        | Classifications              |
  Scenario: Return to Accession
     When the user clicks on 'Spawn'
      And the user clicks on 'Resource' in the spawn dropdown menu
      And the user clicks on 'Return to Accession'
     Then the Accession page is displayed
