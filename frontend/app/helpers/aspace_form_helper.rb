module AspaceFormHelper
  class FormContext

    def initialize(name, values_from, parent)
      @forms = Object.new
      @parent = parent
      @context = [[name, values_from]]
      @path_to_i18n_map = {}

      class << @forms
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::FormTagHelper
        include ActionView::Helpers::FormOptionsHelper
      end

    end


    def readonly?
      false
    end


    def path_to_i18n_map
      @path_to_i18n_map
    end


    def set_index(template, idx)
      template.gsub(/\[\]$/, "[#{idx}]")
    end


    def list_for(objects, context_name, &block)

      objects ||= []
      result = ""

      objects.each_with_index do |object, idx|
        push(set_index(context_name, idx), object) do
          result << "<li class=\"subrecord-form-wrapper\" data-index=\"#{idx}\" data-object-name=\"#{context_name.gsub(/\[\]/,"").singularize}\">"
          result << hidden_input("lock_version")
          result << @parent.capture(object, &block)
          result << "</li>"
        end
      end

      ("<ul data-name-path=\"#{set_index(self.path(context_name), '${index}')}\" " +
       " data-id-path=\"#{id_for(set_index(self.path(context_name), '${index}'), false)}\" " +
       " class=\"subrecord-form-list\">#{result}</ul>").html_safe

    end


    def fields_for(object, context_name, &block)

      result = ""

      push(context_name, object) do
        result << hidden_input("lock_version", object["lock_version"])
        result << @parent.capture(object, &block)
      end

      ("<div data-name-path=\"#{set_index(self.path(context_name), '${index}')}\" " +
        " data-id-path=\"#{id_for(set_index(self.path(context_name), '${index}'), false)}\" " +
        " class=\"subrecord-form-fields-for\">#{result}</div>").html_safe

    end


    def form_top
      @context[0].first
    end


    def id
      "form_#{form_top}"
    end


    # Turn a name like my[nested][object][0][title] into the equivalent JSON
    # path (my/nested/object/0/title)
    def name_to_json_path(name)
      name.gsub(/[\[\]]+/, "/").gsub(/\/+$/, "").gsub(/^\/+/, "")
    end


    def path(name = nil)
      names = @context.map(&:first)
      tail = names.drop(1)
      tail += [name] if name

      path = tail.map {|e|
        if e =~ /(.*?)\[([0-9]+)?\]$/
          "[#{$1}][#{$2}]"
        else
          "[#{e}]"
        end
      }.join("")

      if name
        @path_to_i18n_map[name_to_json_path(path)] = i18n_for(name)
      end

      "#{names.first}#{path}"
    end

    def parent_context
      form_top
    end


    def obj
      @context.last.second
    end


    def [](key)
      obj[key]
    end


    def push(name, values_from = {})
      @context.push([name, values_from])
      yield(self)
      @context.pop
    end


    def i18n_for(name)
      "#{@active_template or form_top}.#{name.to_s.gsub(/\[\]$/, "")}"
    end


    def path_to_i18n_key(path)
      path_to_i18n_map[path]
    end


    def exceptions_for_js(exceptions)
      result = {}
      [:errors, :warnings].each do |condition|
        if exceptions[condition]
          result[condition] = exceptions[condition].keys.map {|property|
            id_for_javascript(property)
          }
        end
      end

      result.to_json.html_safe
    end


    def id_for_javascript(name)
      "#{form_top}#{name.split("/").collect{|a| "[#{a}]"}.join}".gsub(/[\[\]\/]/, "_")
    end


    def id_for(name, qualify = true)
      name = path(name) if qualify

      name.gsub(/[\[\]]/, '_')
    end


    def label_and_textfield(name, opts = {})
      label_with_field(name, textfield(name, obj[name], opts[:field_opts] || {}))
    end

    def label_and_date(name, opts = {})
      field_opts = (opts[:field_opts] || {}).merge({
        :class => "date-field",
        :placeholder => "YYYY-MM-DD",
        :"data-date-format" => "yyyy-mm-dd",
        :"data-date" => Date.today.strftime('%Y-%m-%d')
      })
      label_with_field(name, textfield(name, obj[name], field_opts))
    end

    def label_and_textarea(name, opts = {})
      label_with_field(name, textarea(name, obj[name], opts))
    end


    def label_and_select(name, options, opts = {})
      options = ([""] + options) if opts[:nodefault]
      label_with_field(name, select(name, options, opts[:field_opts] || {}))
    end


    def label_and_password(name, opts = {})
      label_with_field(name, password(name, obj[name], opts[:field_opts] || {}))
    end


    def label_and_boolean(name, opts = {}, default = false, force_checked = false)
      label_with_field(name, checkbox(name, opts, default, force_checked))
    end


    def label_and_readonly(name, default = "", opts = {})
      value = obj[name]

      if opts.has_key? :controls_class
        opts[:controls_class] << " label-only"
      else
        opts[:controls_class] = " label-only"
      end

      label_with_field(name, value.blank? ? default : value , opts)
    end


    def select(name, options, opts = {})
      @forms.select_tag(path(name), @forms.options_for_select(options, obj[name]), {:id => id_for(name)}.merge!(opts))
    end


    def textarea(name = nil, value = "", opts =  {})
      @forms.text_area_tag(path(name), value,  {:id => id_for(name), :rows => 3}.merge(opts))
    end


    def textfield(name = nil, value = "", opts =  {})
      @forms.tag("input", {:id => id_for(name), :type => "text", :value => value, :name => path(name)}.merge(opts),
                 false, false)
    end


    def password(name = nil, value = "", opts =  {})
      @forms.tag("input", {:id => id_for(name), :type => "password", :value => value, :name => path(name)}.merge(opts),
                 false, false)
    end

    def jsonmodel_options_for(model, property, add_empty_options = false)
      options = []
      options.push(["",""]) if add_empty_options
      jsonmodel_enum_for(model, property).each do |v|
        options.push([I18n.t(i18n_for("#{property}_#{v}"), :default => v), v])
      end

      options
    end

    def jsonmodel_enum_for(model, property)
      jsonmodel_schema_definition(model, property)["enum"]
    end

    def jsonmodel_schema_definition(model, property)
      JSONModel(model).schema["properties"][property]
    end

    def options_for(property, values)
      options = []
      values.each do |v|
        options.push([I18n.t(i18n_for("#{property}_#{v}"), :default => v), v])
      end
      options.sort! {|a, b| a[0] <=> b[0]}
      options
    end

    def hidden_input(name, value = nil)
      value = obj[name] if value.nil?
      @forms.tag("input", {:id => id_for(name), :type => "hidden", :value => value, :name => path(name)},
                 false, false)
    end

    def emit_template(name, *args)
      if !@parent.templates[name]
        raise "No such template: #{name.inspect}"
      end

      old = @active_template
      @active_template = name
      @parent.templates[name].call(self, *args)
      @active_template = old

    end

    def label_and_fourpartid
      field_html =  textfield("id_0", obj["id_0"], :class=> "id_0", :size => 10)
      field_html << textfield("id_1", obj["id_1"], :class=> "id_1", :size => 10, :disabled => obj["id_0"].blank? && obj["id_1"].blank?)
      field_html << textfield("id_2", obj["id_2"], :class=> "id_2", :size => 10, :disabled => obj["id_1"].blank? && obj["id_2"].blank?)
      field_html << textfield("id_3", obj["id_3"], :class=> "id_3", :size => 10, :disabled => obj["id_2"].blank? && obj["id_3"].blank?)
      @forms.content_tag(:div, (I18n.t(i18n_for("id_0")) + field_html).html_safe, :class=> "identifier-fields")
      label_with_field("id_0", field_html, :control_class => "identifier-fields")
    end

    def label(name, opts = {})
      "<label class=\"control-label\" for=\"#{id_for(name)}\">#{I18n.t(i18n_for(name))}</label>".html_safe
    end

    def radio(name, value)
      options = {:id => "#{id_for(name)}_#{value}", :type => "radio", :value => value, :name => path(name)}
      options[:checked] = "checked" if obj[name] == value

      @forms.tag("input", options, false, false)
    end

    def checkbox(name, opts = {}, default = true, force_checked = false)
      options = {:id => "#{id_for(name)}", :type => "checkbox", :name => path(name), :value => "1"}
      options[:checked] = "checked" if force_checked or (obj[name] === true) or (obj[name] === "true") or (obj[name].nil? and default)

      @forms.tag("input", options.merge(opts), false, false)
    end

    def required?(name)
      if obj["jsonmodel_type"]
        property_schema = jsonmodel_schema_definition(obj["jsonmodel_type"], name)
        return property_schema && property_schema["ifmissing"] === "error"
      end
      false
    end

    def label_with_field(name, field_html, opts = {})
      control_group_classes = "control-group"
      control_group_classes << " required" if opts["required"] or required?(name)
      control_group_classes << " #{opts[:control_class]}" if opts.has_key? :control_class

      controls_classes = "controls"
      controls_classes << " #{opts[:controls_class]}" if opts.has_key? :controls_class

      control_group = "<div class=\"#{control_group_classes}\">"
      control_group << label(name, opts[:label_opts])
      control_group << "<div class=\"#{controls_classes}\">"
      control_group << field_html
      control_group << "</div>"
      control_group << "</div>"
      control_group.html_safe
    end
  end


  class ReadOnlyContext < FormContext

    def readonly?
      true
    end

    def select(name, options, opts = {})
      return nil if obj[name].blank?
      I18n.t("#{i18n_for(name)}_#{obj[name]}", :default => obj[name])
    end

    def textfield(name = nil, value = "", opts =  {})
      return "" if value.blank?
      CGI::escapeHTML(value)
    end

    def textarea(name = nil, value = "", opts =  {})
      return "" if value.blank?
      @parent.preserve_newlines(CGI::escapeHTML(value))
    end

    def checkbox(name, opts = {}, default = true, force_checked = false)
      ((obj[name] === true) || obj[name] === "true") ? "True" : "False"
    end

    def label_with_field(name, field_html, opts = {})
      return "" if field_html.blank?
      super(name, field_html, opts.merge({:controls_class => "label-only"}))
    end

    def label_and_fourpartid
      fourpart_html = "<div class='identifier-display'>"+
                        "<span class='identifier-display-part'>#{obj["id_0"]}</span>" +
                        "<span class='identifier-display-part'>#{obj["id_1"]}</span>" +
                        "<span class='identifier-display-part'>#{obj["id_2"]}</span>" +
                        "<span class='identifier-display-part'>#{obj["id_3"]}</span>" +
                      "</div>"

      label_with_field("id_0", fourpart_html)
    end

    def label_and_date(name, opts = {})
      label_with_field(name, obj[name].blank? ? "" : Date.strptime(obj[name], "%Y-%m-%d").strftime("%Y-%m-%d"))
    end
  end


  def form_context(name, values_from = {}, &body)
    context = FormContext.new(name, values_from, self)

    # Not feeling great about this, but we render the form twice: the first pass
    # sets up the mapping from form input names to i18n keys, while the second
    # actually uses that map to set the labels correctly.
    capture(context, &body)

    s = "<div class=\"form-context\" id=\"form_#{name}\">".html_safe
    s << context.hidden_input("lock_version", values_from["lock_version"])
    s << capture(context, &body)
    s << templates_for_js
    s << "</div>".html_safe

    s
  end


  def templates
    @templates ||= {}
    @templates
  end


  def define_template(name, &block)
    @templates ||= {}
    @templates[name] = block
  end


  def templates_for_js
    result = ""

    return result if @templates.blank?

    @templates.each do |name, template|
      context = FormContext.new("${path}", {}, self)

      def context.id_for(name, qualify = true)
        name = path(name) if qualify

        name.gsub(/[\[\]]/, '_').gsub('${path}', '${id_path}')
      end

      context.instance_eval do
        @active_template = name
      end

      result << "<div id=\"template_#{name}\"><!--"
      result << capture(context, &template)
      result << "--></div>"
    end

    result.html_safe
  end

  def readonly_context(name, values_from = {}, &body)
    context = ReadOnlyContext.new(name, values_from, self)

    # Not feeling great about this, but we render the form twice: the first pass
    # sets up the mapping from form input names to i18n keys, while the second
    # actually uses that map to set the labels correctly.
    capture(context, &body)

    s = "<div class=\"readonly-context form-horizontal\">".html_safe
    s << capture(context, &body)
    s << "</div>".html_safe

    s
  end

  PROPERTIES_TO_EXCLUDE_FROM_READ_ONLY_VIEW = ["jsonmodel_type", "lock_version", "resolved", "uri"]

  def read_only_view(hash, opts = {})
    jsonmodel_type = hash["jsonmodel_type"]
    schema = JSONModel(jsonmodel_type).schema
    html = "<div class='form-horizontal'>"

    hash.reject {|k,v| PROPERTIES_TO_EXCLUDE_FROM_READ_ONLY_VIEW.include?(k)}.each do |property, value|

      if schema and schema["properties"].has_key?(property)
        if schema["properties"][property].has_key?("enum")
          value = I18n.t("#{jsonmodel_type.to_s}.#{property}_#{value}", value)
        elsif schema["properties"][property]["type"] === "boolean"
          value = value === true ? "True" : "False"
        elsif schema["properties"][property]["type"] === "array"
          # this view doesn't support arrays
          next
        elsif hash.has_key?("resolved") and hash["resolved"].has_key?(property)
          # don't display a resolved attribute... as it's probably just a URI
          next
        elsif value.kind_of? Hash
          # can't display an object either
          next
        end
      end

      html << "<div class='control-group'>"
      html << "<div class='control-label'>#{I18n.t("#{jsonmodel_type.to_s}.#{property}")}</div>"
      html << "<div class='controls label-only'>#{value}</div>"
      html << "</div>"

    end

  html << "</div>"

    html.html_safe
  end

  def preserve_newlines(string)
    string.gsub(/\n/, '<br>')
  end

end
