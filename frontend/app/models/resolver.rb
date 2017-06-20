class Resolver
  attr_reader :repository

  def initialize(uri)
    @uri = uri

    jsonmodel_properties = JSONModel.parse_reference(@uri)

    @id = jsonmodel_properties[:id]
    @repository = jsonmodel_properties[:repository]
    @jsonmodel_type = jsonmodel_properties[:type]
    @repo_id = JSONModel.parse_reference(@repository)[:id] if @repository
  end


  def edit_uri
    uri_properties = default_uri_properties

    uri_properties[:action] = :edit

    uri_properties
  end


  def view_uri
    uri_properties = default_uri_properties

    uri_properties[:action] = :show

    uri_properties
  end


  private
  
  def default_uri_properties
    uri_properties = {
      :controller => @jsonmodel_type.to_s.pluralize.intern,
      :id => @id
    }

    if @jsonmodel_type.start_with? "agent_"
      uri_properties[:controller] = :agents
      uri_properties[:agent_type] = @jsonmodel_type
    elsif @jsonmodel_type === "archival_object"
      ao = JSONModel(:archival_object).find(@id, :repo_id => @repo_id)
      uri_properties[:controller] = :resources
      uri_properties[:id] = JSONModel(:resource).id_for(ao["resource"]["ref"])
      uri_properties[:anchor] = "tree::archival_object_#{@id}"
    elsif @jsonmodel_type === "digital_object_component"
      doc = JSONModel(:digital_object_component).find(@id, :repo_id => @repo_id)
      uri_properties[:controller] = :digital_objects
      uri_properties[:id] = JSONModel(:digital_object).id_for(doc["digital_object"]["ref"])
      uri_properties[:anchor] = "tree::digital_object_component_#{@id}"
    elsif @jsonmodel_type === "classification_term"
      ct = JSONModel(:classification_term).find(@id, :repo_id => @repo_id)
      uri_properties[:controller] = :classifications
      uri_properties[:id] = JSONModel(:classification).id_for(ct["classification"]["ref"])
      uri_properties[:anchor] = "tree::classification_term_#{@id}"
    elsif @jsonmodel_type === "collection_management"
      cm = JSONModel(:collection_management).find(@id, :repo_id => @repo_id)
      parent = JSONModel.parse_reference(cm['parent']['ref'])
      uri_properties[:controller] = parent[:type].to_s.pluralize.intern
      uri_properties[:id] = parent[:id]
      uri_properties[:anchor] = "collection_management"
    end

    uri_properties
  end

end
