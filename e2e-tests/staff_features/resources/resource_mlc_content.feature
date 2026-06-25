Feature: MLC content display

  Background:
    Given an administrator user is logged in
    Given a Resource has been created

  Scenario: Current Language selector from edit mode resource toolbar
    Given the Resource is opened in edit mode
     When the user clicks on "Current Language"
     Then the user sees the "English" option in the "Current Language" dropdown
      And the user sees the "Spanish" option in the "Current Language" dropdown
      And the user sees the "French" option in the "Current Language" dropdown
      And the user sees the "German" option in the "Current Language" dropdown

  Scenario Outline: MLC default language preview appears on mlc content fields
    Given the Resource is opened in edit mode
     Then the user sees the MLC default language preview before the "<record_type>" "<field>" label
      And the user sees the default language preview summary text "SPA"
      And the default language preview should be present but hidden
      And the user sees a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type | field                         |
          | resource    | title                         |
          | resource    | finding_aid_title             |
          | resource    | finding_aid_subtitle          |
          | resource    | finding_aid_author            |
          | resource    | finding_aid_sponsor           |
          | resource    | finding_aid_edition_statement |
          | resource    | finding_aid_series_statement  |
          | resource    | finding_aid_note              |
          | resource    | repository_processing_note    |
          | resource    | finding_aid_filing_title      |

  Scenario: Current Language selector from view mode resource toolbar
    Given the Resource is opened in the view mode
     When the user clicks on "Current Language"
     Then the user sees the "English" option in the "Current Language" dropdown
      And the user sees the "Spanish" option in the "Current Language" dropdown
      And the user sees the "French" option in the "Current Language" dropdown
      And the user sees the "German" option in the "Current Language" dropdown

  Scenario Outline: MLC badge does not appear in read mode
    Given the Resource is opened in the view mode
     Then the user should not see the MLC default language preview before the "<record_type>" "<field>" label
      And the user should not see a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type | field                         |
          | resource    | title                         |
          | resource    | finding_aid_title             |
          | resource    | finding_aid_subtitle          |
          | resource    | finding_aid_author            |
          | resource    | finding_aid_sponsor           |
          | resource    | finding_aid_edition_statement |
          | resource    | finding_aid_series_statement  |
          | resource    | finding_aid_note              |
          | resource    | repository_processing_note    |
          | resource    | finding_aid_filing_title      |

  @mlc_enabled
  Scenario: Current language badge appears on all subrecords when mlc enabled
    Given a second language of description has been added to the Resource
      And the Resource is opened in edit mode
     Then the user should see language badges on all subrecords

  Scenario: Current language badge does not appear when mlc disabled
    Given the Resource is opened in edit mode
     Then the user should not see a language badge
