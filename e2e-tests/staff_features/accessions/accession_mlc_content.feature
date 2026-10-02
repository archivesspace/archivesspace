Feature: MLC content display

  Background:
    Given an administrator user is logged in
      And an Accession has been created

  @mlc_enabled
  Scenario: Current Language selector from edit mode resource toolbar
    Given a second language of description has been added to the Accession
      And the Accession is opened in edit mode
     When the user clicks on "Current Language"
     Then the user sees the "English" option in the "Current Language" dropdown
      And the user sees the "German" option in the "Current Language" dropdown

  Scenario Outline: MLC default language preview appears on mlc content fields
    Given the Accession is opened in edit mode
     Then the user sees the MLC default language preview before the "<record_type>" "<field>" label
      And the user sees the default language preview summary text "SPA"
      And the default language preview should be present but hidden
      And the user sees a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type | field                    |
          | accession   | title                    |
          | accession   | content_description      |
          | accession   | condition_description    |
          | accession   | disposition              |
          | accession   | inventory                |
          | accession   | provenance               |
          | accession   | general_note             |
          | accession   | access_restrictions_note |
          | accession   | use_restrictions_note    |

  @mlc_enabled
  Scenario: Current Language selector from view mode resource toolbar
    Given a second language of description has been added to the Accession
      And the Accession is opened in the view mode
     When the user clicks on "Current Language"
     Then the user sees the "English" option in the "Current Language" dropdown
      And the user sees the "German" option in the "Current Language" dropdown

  Scenario Outline: MLC badge does not appear in read mode
    Given the Accession is opened in the view mode
     Then the user should not see the MLC default language preview before the "<record_type>" "<field>" label
      And the user should not see a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type | field                    |
          | accession   | title                    |
          | accession   | content_description      |
          | accession   | condition_description    |
          | accession   | disposition              |
          | accession   | inventory                |
          | accession   | provenance               |
          | accession   | general_note             |
          | accession   | access_restrictions_note |
          | accession   | use_restrictions_note    |

  @mlc_enabled
  Scenario: Current language badge appears on all subrecords when mlc enabled
    Given a second language of description has been added to the Accession
      And the Accession is opened in edit mode
     Then the user should see language badges on all subrecords

  Scenario: Current Language selector does not appear when mlc disabled
    Given the Accession is opened in edit mode
     Then the user should not see the "Current Language" dropdown

  Scenario: Current language badge does not appear when mlc disabled
    Given the Accession is opened in edit mode
     Then the user should not see a language badge
