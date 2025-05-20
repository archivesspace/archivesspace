Feature: Accession Accession Spawn
  Background:
    Given an administrator user is logged in
      And an Accession has been created
      And the Accession is opened in edit mode
  Scenario: Accession Spawn Accession page is opened
     When the user clicks on 'Spawn'
      And the user clicks on 'Accession' in the spawn dropdown menu
     Then the New Accession page is displayed
      And the Accession has been spawned from Accession info message is displayed
  Scenario: Successfully spawn a new accession from an existing accession - not linked
    Given the user is on the New Accession page spawned from the original Accession
     When the user fills in 'Identifier'
      And the user clicks on 'Save'
     Then the Accession is created
      And the new Accession is not linked to the original Accession
  Scenario: Successfully spawn a new accession from an existing accession - linked
    Given the user is on the New Accession page spawned from the original Accession
     When the user fills in 'Identifier'
      And the user links to the original Accession in the 'Related Accessions' form
      And the user clicks on 'Save'
     Then the Accession is created
      And the new Accession is linked to the original Accession
