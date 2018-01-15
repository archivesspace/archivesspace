require_relative 'utils'

Sequel.migration do
  up do
    if $db_type == :mysql
      run "DROP FUNCTION IF EXISTS GetAccessionCatalogedDate;"
      run "DROP FUNCTION IF EXISTS GetAccessionDateExpression;"
      run "DROP FUNCTION IF EXISTS GetAccessionIdForInstance;"
      run "DROP FUNCTION IF EXISTS GetAccessionsCataloged;"
      run "DROP FUNCTION IF EXISTS GetAccessionsExtent;"
      run "DROP FUNCTION IF EXISTS GetAccessionsProcessed;"
      run "DROP FUNCTION IF EXISTS GetAccessionsWithRestrictions;"
      run "DROP FUNCTION IF EXISTS GetAccessionsWithRightsTransferred;"
      run "DROP FUNCTION IF EXISTS GetAgentMatch;"
      run "DROP FUNCTION IF EXISTS GetAgentsCorporate;"
      run "DROP FUNCTION IF EXISTS GetAgentsFamily;"
      run "DROP FUNCTION IF EXISTS GetAgentsPersonal;"
      run "DROP FUNCTION IF EXISTS GetAgentsSoftware;"
      run "DROP FUNCTION IF EXISTS GetAgentUniqueName;"
      run "DROP FUNCTION IF EXISTS GetDigitalObjectId;"
      run "DROP FUNCTION IF EXISTS GetFaxNumber;"
      run "DROP FUNCTION IF EXISTS GetInstanceCount;"
      run "DROP FUNCTION IF EXISTS GetLanguageCount;"
      run "DROP FUNCTION IF EXISTS GetPhoneNumber;"
      run "DROP FUNCTION IF EXISTS GetResourceContainerSummary;"
      run "DROP FUNCTION IF EXISTS GetResourceCreator;"
      run "DROP FUNCTION IF EXISTS GetResourceExtentType;"
      run "DROP FUNCTION IF EXISTS GetResourceHasCreator;"
      run "DROP FUNCTION IF EXISTS GetResourceHasSource;"
      run "DROP FUNCTION IF EXISTS GetResourceIdForInstance;"
      run "DROP FUNCTION IF EXISTS GetResourcesExtent;"
      run "DROP FUNCTION IF EXISTS GetResourcesWithFindingAids;"
      run "DROP FUNCTION IF EXISTS GetResourcesWithRestrictions;"
      run "DROP FUNCTION IF EXISTS GetResourceTitleForInstance;"
      run "DROP FUNCTION IF EXISTS GetStatusCount;"
      run "DROP FUNCTION IF EXISTS GetTermTypeCount;"
      run "DROP FUNCTION IF EXISTS GetTotalAccessions;"
      run "DROP FUNCTION IF EXISTS GetTotalResourcesItems;"
      run "DROP FUNCTION IF EXISTS GetTotalSubjects;"
    end
  end
end
