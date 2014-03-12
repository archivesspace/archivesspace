module PluginHelper

  def sidebar_plugins_for(record)
    result = ''
    jsonmodel_type = record['jsonmodel_type']
    Plugins.plugins_for(jsonmodel_type).each do |plugin|
      name = Plugins.parent_for(plugin, jsonmodel_type)['name']
      if not controller.action_name === "show" or record.send(name).length > 0
        result << '<li>'
        result << "<a href='##{jsonmodel_type}_#{name}_'>"
        result << I18n.t("plugins.#{plugin}._plural")
        result << '<span class="icon-chevron-right"></span></a></li>'
      end
    end
    result.html_safe
  end


  def show_plugins_for(record, context)
    result = ''
    jsonmodel_type = record['jsonmodel_type']
    Plugins.plugins_for(jsonmodel_type).each do |plugin|
      name = Plugins.parent_for(plugin, jsonmodel_type)['name']
      if record.send(name).length > 0
        result << render(:partial => "#{name}/show", :formats => [:html], :handlers => [:erb],
                         :locals => { name.intern => record.send(name),
                           :context => context, :section_id => "#{jsonmodel_type}_#{name}_" })
      end
    end
    result.html_safe
  end


  def form_plugins_for(jsonmodel_type, context)
    result = ''
    Plugins.plugins_for(jsonmodel_type).each do |plugin|
      parent = Plugins.parent_for(plugin, jsonmodel_type)

      result << render(:partial => "shared/subrecord_form", :formats => [:html], :handlers => [:erb],
                       :locals => {:form => context, :name => parent['name'],
                         :cardinality => parent['cardinality'], :plugin => true})

    end
    result.html_safe
  end

end
