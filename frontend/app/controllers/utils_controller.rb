class UtilsController  < ApplicationController

  set_access_control  :public => [:generate_sequence, :shortcuts],
                      "view_repository" => [:list_properties]


  def generate_sequence
    render :json => SequenceGenerator.from_params(params)
  end


  def list_properties
    resource_type = params[:resource_type]

    list = []

    JSONModel(resource_type).schema['properties'].each do |name, defn|

      next if params['editable'] && defn.has_key?('dynamic_enum')
      next if params['editable'] && %w(uri jsonmodel_type).include?(name)
      next if params['editable'] && defn['readonly']
      next if params['type'] && defn['type'] != params['type']

      list << [name, I18n.t("#{resource_type}.#{name}")]
    end

    render :json => list
  end


  def shortcuts
    render_aspace_partial :partial => "shared/modal", :locals => {:title => I18n.t("shortcuts.quick_reference_window"), :partial => "shared/shortcuts", :large => true}
  end

end
