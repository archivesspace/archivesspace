Feature: Resource Export
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Resource export EAD
     When the user clicks on 'Export'
      And the user clicks on 'Download EAD' in the dropdown menu
     Then an EAD XML file is downloaded
  Scenario: Resource export MARCXML
     When the user clicks on 'Export'
      And the user clicks on 'Download MARCXML' in the dropdown menu
     Then a MARC 21 XML file is downloaded
  Scenario: Resource export container labels
     When the user clicks on 'Export'
      And the user clicks on 'Download Container Labels' in the dropdown menu
     Then the 'container_labels_job' job page is displayed
  Scenario: Resource export container template
     When the user clicks on 'Export'
      And the user clicks on 'Download Container Template' in the dropdown menu
     Then the Container Template CSV file is downloaded
  Scenario: Resource export digital object template
     When the user clicks on 'Export'
      And the user clicks on 'Download Digital Object Template' in the dropdown menu
     Then a Digital Object template CSV file is downloaded prefilled with resource URI
  Scenario: Resource export in pdf
     When the user clicks on 'Export'
      And the user clicks on 'Generate PDF' in the dropdown menu
     Then the 'print_to_pdf_job' job page is displayed
