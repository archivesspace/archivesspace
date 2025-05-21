Feature: Top Containers Bulk Operations
  Background:
    Given an administrator user is logged in
      And a Resource with two Top Containers has been created
      And the user is on the Top Containers page
      And the the two Top Containers are displayed in the search results
  Scenario: Select all Top Containers
     When the user checks the checkbox in the header row
     Then all the Top Containers are selected
      And the 'Bulk Operations' button is enabled
  Scenario: Unselect all Top Containers
    Given all Top Containers are selected
     When the user checks the checkbox in the header row
     Then all the Top Containers are not selected
      And the 'Bulk Operations' button is disabled
  Scenario: Update ILS holdings IDs of a Top Container
    Given the Top Container A is selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Update ILS Holding IDs' in the dropdown menu
      And the user fills in 'ILS Holding ID' with '123456789'
      And the user clicks on 'Update 1 records'
     Then the 'Top Containers' updated message is displayed
  Scenario: Update Container Profile of a Top Container by browsing
    Given the Top Container A is selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Update Container Profiles' in the dropdown menu
      And the user clicks on the dropdown in the Bulk Update form
      And the user clicks on 'Browse' in the dropdown menu
      And the user selects Container Profile in the modal
      And the user clicks on 'Link' in the Browse Container Profiles modal
      And the user clicks on 'Update 1 records'
      And the Top Container A profile is linked to the Container Profile
  Scenario: Update Container Profile of a Top Container by creating Container Profile
    Given the Top Container A is selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Update Container Profiles' in the dropdown menu
      And the user clicks on the dropdown in the Bulk Update form
      And the user clicks on 'Create' in the dropdown menu
      And the user fills in 'Name' in the Create Container Profiles modal
      And the user fills in 'Depth' with '1.1' in the Create Container Profiles modal
      And the user fills in 'Height' with '1.2' in the Create Container Profiles modal
      And the user fills in 'Width' with '1.3' in the Create Container Profiles modal
      And the user clicks on 'Create and Link'
      And the user clicks on 'Update 1 records'
      And the Top Container A profile is linked to the created Container Profile
  Scenario: Update Single Location of a Top Container by browsing
    Given the Top Container A is selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Update Locations: Single Location' in the dropdown menu
      And the user clicks on the dropdown in the Bulk Update form
      And the user clicks on 'Browse' in the dropdown menu
      And the user selects Location in the modal
      And the user clicks on 'Link' in the Browse Locations modal
      And the user clicks on 'Update 1 records'
      And the Top Container profile is linked to the Location
  Scenario: Update Single Location of a Top Container by creating Location
    Given the Top Container A is selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Update Locations: Single Location' in the dropdown menu
      And the user clicks on the dropdown in the Bulk Update form
      And the user clicks on 'Create' in the dropdown menu
      And the user fills in 'Building' with 'Test Building' in the Create Location modal
      And the user fills in 'Barcode' with '123456789' in the Create Location modal
      And the user clicks on 'Create and Link' in the Create Location modal
      And the user clicks on 'Update 1 records'
      And the Top Container profile is linked to the created Location
  Scenario: Remove Locations from Top Containers without replacing the Locations
      And the two Top Containers are selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Update Locations: Multiple Locations' in the dropdown menu
      And the user clicks on 'Update 2 records'
     Then the Locations are removed from the Top Containers
  Scenario: Add Barcodes associated with Top Containers successfully
      And the two Top Containers are selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Rapid Barcode Entry' in the dropdown menu
      And the user fills in New Barcode for Top Container A
      And the user fills in New Barcode for Top Container B
      And the user clicks on 'Update 2 records'
      And the Top Containers have new Barcodes
  Scenario: Barcodes associated with Top Containers are not added
    Given the two Top Containers are selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Rapid Barcode Entry' in the dropdown menu
      And the user fills in New Barcode for Top Container A with '123456789'
      And the user fills in New Barcode for Top Container B with '123456789'
      And the user clicks on 'Update 2 records'
     Then the following error message is displayed
       |Barcode - A barcode must be unique within a repository|
  Scenario: Merge two Top Containers
    Given the two Top Containers are selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Merge Top Containers' in the dropdown menu
      And the user selects the Top Container B in the Merge Top Containers modal
      And the user clicks on 'Select merge destination' in the modal
      And the user clicks on 'Merge 2 records' in the Confirm Merge Top Containers modal
     Then the 'Top Container(s)' merged message is displayed
      And the Top Container A is deleted
  Scenario: Delete two Top Containers
    Given the two Top Containers are selected
     When the user clicks on 'Bulk Operations'
      And the user clicks on 'Delete Top Containers' in the dropdown menu
      And the user clicks on 'Delete 2 records' in the modal
     Then the 'Top Containers' deleted message is displayed
      And the two Top Containers are deleted
