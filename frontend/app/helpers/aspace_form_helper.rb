require 'mixed_content_parser'

module AspaceFormHelper

  COMBOBOX_MIN_LIMIT = 50 # if a <select> has equal or more options than this value, output a combobox

  class FormHelpers
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::FormOptionsHelper
  end

  class FormContext

    def initialize(name, values_from, parent)
      values = values_from.is_a?(JSONModelType) ? values_from.to_hash(:raw) : values_from

      @forms = FormHelpers.new
      @parent = parent
      @context = [[name, values]]
    end


    def h(str)
      ERB::Util.html_escape(str)
    end


    def clean_mixed_content(content, root_url)
      content = content.to_s
      return content if content.blank?

      MixedContentParser::parse(content, root_url, { :wrap_blocks => false } ).to_s.html_safe
    end


    def readonly?
      false
    end


    def set_index(template, idx)
      template.gsub(/\[\]$/, "[#{idx}]")
    end

    # ANW-617:
    # TODO: Ideally, this method should generate a full URL, with the value from AppConfig[:public_url], so the link is fully actionable.
    # Ran into a a bug (with AS? or deeper?) where the value of AppConfig[:public_url] was being changed at runtime simply by getting it's value, with code like base_url = AppConfig[:public_url].
    # For now, this method generates a relative URL, like '\resources\Resource A' to avoid this.
    def slug_url_field(name, repo_slug = nil, generate_url_with_repo_slug = nil)
      url = ""
      html = ""

      case obj['jsonmodel_type']
      when 'resource'
        scope = :repo
        route = "resources"
      when 'accession'
        scope = :repo
        route = "accessions"
      when 'classification'
        scope = :repo
        route = "classifications"
      when 'classification_term'
        scope = :repo
        route = "classification_terms"
      when 'digital_object'
        scope = :repo
        route = "digital_objects"
      when 'repository'
        scope = :global
        route = "repositories"
      when 'agent_person'
        scope = :global
        route = "agents"
      when 'agent_family'
        scope = :global
        route = "agents"
      when 'agent_software'
        scope = :global
        route = "agents"
      when 'agent_corporate_entity'
        scope = :global
        route = "agents"
      when 'subject'
        scope = :global
        route = "subjects"
      when 'archival_object'
        scope = :repo
        route = "archival_objects"
      when 'digital_object_component'
        scope = :repo
        route = "digital_object_components"
      end

      # For repo scoped objects,
      # if we have access to the repo slug in the session and the repo scoped URLs are enabled
      # generate link with repo slug
      if !obj['slug'].nil? &&
         !obj['slug'].empty? &&
         AppConfig[:use_human_readable_urls]

        if scope == :repo
          if generate_url_with_repo_slug && repo_slug
            url << "/" + "repositories" + "/"
            url << repo_slug
          end
        end

        url << "/" + route + "/" + obj['slug']
      else
        url = obj['uri']
      end

      url.to_s
    end

    # renders a list of form element sets from a template. Each item will be re-orderable.
    # Objects should be an array.
    def list_for(objects, context_name, &block)
      objects ||= []
      result = ""

      objects.each_with_index do |object, idx|
        push(set_index(context_name, idx), object) do
          result << "<li id=\"#{current_id}\" class=\"subrecord-form-wrapper\" data-index=\"#{idx}\" data-object-name=\"#{context_name.gsub(/\[\]/, "").singularize}\">"
          result << hidden_input("lock_version") if obj.respond_to?(:has_key?) && obj.has_key?("lock_version")
          result << @parent.capture(object, idx, &block)
          result << "</li>"
        end
      end

      ("<ul data-name-path=\"#{set_index(self.path(context_name), '${index}')}\" " +
       " data-id-path=\"#{id_for(set_index(self.path(context_name), '${index}'), false)}\" " +
       " class=\"subrecord-form-list\">#{result}</ul>").html_safe
    end


    # renders a single template containing form elements.
    def fields_for(object, context_name, &block)
      result = ""

      push(context_name, object) do
        result << hidden_input("lock_version", object["lock_version"]) if object
        result << @parent.capture(object, &block)
      end

      extra_classes = ""

      # ANW-429: Add class to top level div so element can be switched out by JS based on user form input
      # TODO: refactor
      extra_classes += "sdl-subrecord-form" if context_name == "structured_date_range" || context_name == "structured_date_single"


      ("<div data-name-path=\"#{set_index(self.path(context_name), '${index}')}\" " +
        " data-id-path=\"#{id_for(set_index(self.path(context_name), '${index}'), false)}\" " +
        " class=\"subrecord-form-fields-for mt-1 #{extra_classes}\">#{result}</div>").html_safe
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

      "#{names.first}#{path}"
    end


    def help_path_for(name)
      names = @context.map(&:first)
      return "#{names[-1].to_s.gsub(/\[.*\]/, "").singularize}_#{name}" if names.length > 0
      name
    end


    def parent_context
      form_top
    end


    def current_context
      @context.last
    end


    def obj
      @context.last.second
    end


    def [](key)
      obj[key]
    end


    def push(name, values_from = {})
      path(name) # populate the i18n mapping
      @context.push([name, values_from])
      yield(self)
      @context.pop
    end


    # ignore_form_context will return a translation divorced from the active template
    # or form in which it appears.
    def i18n_for(name, ignore_form_context = false)
      if ignore_form_context
        "#{name.to_s.gsub(/\[\]$/, "")}"
      else
        "#{@active_template or form_top}.#{name.to_s.gsub(/\[\]$/, "")}"
      end
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
      path = name.split("/").collect {|a| "[#{a}]"}.join
      "#{form_top}#{path}".gsub(/[\[\]\/]/, "_")
    end


    def current_id
      path(nil).gsub(/[\[\]]/, '_')
    end

    def id_for(name, qualify = true)
      name = path(name) if qualify

      name.gsub(/[\[\]]/, '_')
    end

    def label_and_textfield(name, opts = {})
      label_with_field(name, textfield(name, obj[name], opts[:field_opts] || {}), opts)
    end

    def label_and_date(name, opts = {})
      field_opts = (opts[:field_opts] || {}).merge({
          :class => "date-field form-control",
          :"data-format" => "yyyy-mm-dd",
          :"data-date" => Date.today.strftime('%Y-%m-%d'),
          :"data-autoclose" => true,
          :"data-force-parse" => false,
          :"data-label" => I18n.t("actions.date_picker_toggle")
      })

      if obj[name].blank? && opts[:default]
        value = opts[:default]
      else
        value = obj[name]
      end

      opts[:col_size] = 4

      date_input = textfield(name, value, field_opts)

      label_with_field(name, date_input, opts)
    end

    def label_and_disabled_checkbox(name)
      html = ""

      html << "<div class='form-group'>"

      html << "<label class='col-sm-2 control-label'>#{name}</label>"
      html << "<div class='col-sm-1'>"
      html << "<input type='checkbox' name='disabled' disabled>"
      html << "</div>"
      html << "</div>"

      return html.html_safe
    end

    def label_and_textarea(name, opts = {})
      label_with_field(name, textarea(name, obj[name] || opts[:default], opts[:field_opts] || {}), opts)
    end


    def label_and_select(name, options, opts = {})
      options = ([""] + options) if opts[:nodefault]
      opts[:field_opts] ||= {}

      opts[:col_size] = 9
      widget = options.length < COMBOBOX_MIN_LIMIT ? select(name, options, opts[:field_opts] || {}) : combobox(name, options, opts[:field_opts] || {})
      label_with_field(name, widget, opts)
    end


    def label_and_password(name, opts = {})
      label_with_field(name, password(name, obj[name], opts[:field_opts] || {}), opts)
    end


    def label_and_boolean(name, opts = {}, default = false, force_checked = false)
      opts[:col_size] = 1
      opts[:controls_class] = "checkbox"
      label_with_field(name, checkbox(name, opts.except(:label_opts), default, force_checked), opts)
    end

    def label_and_readonly(name, default = "", opts = {})
      value = obj[name]
      if !(value.is_a? String)
        value = value.to_s
      end

      begin
        jsonmodel_type = obj["jsonmodel_type"]
        prefix = opts[:plugin] ? 'plugins.' : ''
        schema = JSONModel(jsonmodel_type).schema
        if (schema["properties"][name]&.has_key?('dynamic_enum'))
          value = I18n.t("enumerations.#{schema["properties"][name]["dynamic_enum"]}.#{value}", :default => value)
        elsif schema["properties"][name]&.has_key?("enum")
          property = schema["properties"][name]["enum"]
          value = I18n.t("#{prefix}#{jsonmodel_type.to_s}.#{name}_#{value}", :default => value)
        end
        value = "" unless value.is_a?(String)
      rescue
      end
      if opts.has_key? :controls_class
        opts[:controls_class] << " label-only"
      else
        opts[:controls_class] = " label-only"
      end

      label_with_field(name, value.blank? ? default : value , opts)
    end

    def label_and_merge_select(name, default = "", opts = {})
      value = obj[name]
      begin
        jsonmodel_type = obj["jsonmodel_type"]
        prefix = opts[:plugin] ? 'plugins.' : ''
        schema = JSONModel(jsonmodel_type).schema
        if (schema["properties"][name].has_key?('dynamic_enum'))
          value = I18n.t("enumerations.#{schema["properties"][name]["dynamic_enum"]}.#{value}", :default => value)
        elsif schema["properties"][name].has_key?("enum")
          value = I18n.t("#{prefix}#{jsonmodel_type.to_s}.#{property}_#{value}", :default => value)
        end
        value = "" unless value.is_a?(String)
      rescue
      end
      if opts.has_key? :controls_class
        opts[:controls_class] << " label-only"
      else
        opts[:controls_class] = " label-only"
      end
      if value.blank?
        label_with_field(name, value.blank? ? default : value , opts)
      else
        label_with_field(name, merge_select(name, value, opts), opts)
      end
    end

    # ANW-429: Modified this method so that a disable_replace can be passed in, which will skip the creation of the "replace" checkboxes.
    # This can be used to not render them in case a replace in inappropriate, e.g., the target record has nothing to replace with.
    def merge_select(name, value, opts)
      unless opts[:disable_replace] == true
        value += "<label class='subreplace-control'>".html_safe
        value += merge_checkbox("#{name}", {
          :class => "merge-toggle"}, false, false)
        value += "&#160;<small>".html_safe
        value += I18n.t("actions.merge_replace")
        value += "</small></label>".html_safe
      else
        value += ""
      end
    end

    def combobox(name, options, opts = {})
      select(name, options, opts.merge({ :"data-combobox" => true,
                                         :id => id_for(name) }))
    end


    def select(name, options, opts = {})
      if opts.has_key? :class
        opts[:class] << " form-control"
      else
        opts[:class] = "form-control"
      end
      if opts.has_key? :"data-combobox"
        opts[:role] = "listbox"
        opts[:"aria-label"] = I18n.t(i18n_for(name))
      end
      selection = obj[name]
      selection = selection[0...-4] if selection.is_a? String and selection.end_with?("_REQ")
      @forms.select_tag(path(name), @forms.options_for_select(options, selection || default_for(name) || opts[:default]), {:id => id_for(name)}.merge!(opts))
    end

    def textarea(name = nil, value = "", opts = {})
      value = value[0...-4] if value.is_a? String and value.end_with?("_REQ")
      value = nil if value === "REQ"
      options = {:id => id_for(name), :rows => 3}

      placeholder = I18n.t("#{i18n_for(name)}_placeholder", :default => '')
      options[:placeholder] = placeholder if not placeholder.empty?
      options[:class] = "form-control"

      @forms.text_area_tag(path(name), h(value), options.merge(opts))
    end

    def textarea_ro(name = nil, value = "", opts = {})
      return "" if value.blank?
      opts[:escape] = true unless opts[:escape] == false
      opts[:base_url] ||= "/"
      value = clean_mixed_content(value, opts[:base_url]) if opts[:clean] == true
      value = @parent.preserve_newlines(value) if opts[:clean] == true
      value = CGI::escapeHTML(value) if opts[:escape]
      value.html_safe
    end

    def textfield(name = nil, value = nil, opts = {})
      value ||= obj[name] if !name.nil?

      value = value[0...-4] if value.is_a? String and value.end_with?("_REQ")
      value = nil if value === "REQ"

      options = {:id => id_for(name), :type => "text", :value => h(value), :name => path(name)}

      placeholder = I18n.t("#{i18n_for(name)}_placeholder", :default => '')
      options[:placeholder] = placeholder if not placeholder.empty?
      options[:class] = "form-control"

      value = @forms.tag("input", options.merge(opts),
                 false, false)

      if opts[:automatable]
        by_default = default_for("#{name}_auto_generate") || false
        value << "<label>".html_safe
        value << checkbox("#{name}_auto_generate", {
          :class => "automate-field-toggle", :display_text_when_checked => I18n.t("states.auto_generated")
          }, by_default, false)
        value << "&#160;<small>".html_safe
        value << I18n.t("actions.automate")
        value << "</small></label>".html_safe
      end

      inline_help = I18n.t("#{i18n_for(name)}_inline_help", :default => '')
      if !inline_help.empty?
        value << "<span class=\"help-inline\">#{inline_help}</span>".html_safe
      end

      value
    end


    def password(name = nil, value = "", opts = {})
      @forms.tag("input", {:id => id_for(name), :type => "password", :value => h(value), :name => path(name)}.merge(opts),
                 false, false)
    end

    def hidden_input(name, value = nil, field_opts = {})
      value = obj[name] if value.nil?

      full_name = path(name)

      if value && value.is_a?(Hash) && value.has_key?('ref')
        full_name += '[ref]'
        value = value['ref']
      end

      @forms.tag("input", {:id => id_for(name), :type => "hidden", :value => h(value), :name => full_name}.merge(field_opts),
                 false, false)
    end

    def emit_template(name, *args)
      if !@parent.templates[name]
        raise "No such template: #{name.inspect}"
      end

      old = @active_template
      @active_template = name
      @parent.templates[name][:block].call(self, *args)
      @active_template = old
    end

    def label_and_fourpartid
      field_html =  textfield("id_0", obj["id_0"], :class => "id_0 form-control", :size => 10)
      field_html << textfield("id_1", obj["id_1"], :class => "id_1 form-control", :size => 10, :disabled => obj["id_0"].blank? && obj["id_1"].blank?, :'aria-label' => "id_1")
      field_html << textfield("id_2", obj["id_2"], :class => "id_2 form-control", :size => 10, :disabled => obj["id_1"].blank? && obj["id_2"].blank?, :'aria-label' => "id_2")
      field_html << textfield("id_3", obj["id_3"], :class => "id_3 form-control", :size => 10, :disabled => obj["id_2"].blank? && obj["id_3"].blank?, :'aria-label' => "id_3")
      @forms.content_tag(:div, (I18n.t(i18n_for("id_0")) + field_html).html_safe, :class=> "identifier-fields")
      label_with_field("id_0", field_html, :control_class => "identifier-fields")
    end


    def label(name, opts = {}, classes = [])
      prefix = ''
      prefix << "#{opts[:contextual]}." if opts[:contextual]
      prefix << 'plugins.' if opts[:plugin]

      classes << 'control-label text-right'

      options = {:class => classes.join(' '), :for => id_for(name)}

      unless (tooltip = tooltip(name, prefix)).empty?
        add_tooltip_options(tooltip, options)
      end

      attr_string = options.merge(opts || {})
                      .map {|k, v| '%s="%s"' % [CGI::escapeHTML(k.to_s),
                                                CGI::escapeHTML(v.to_s)]}
                      .join(' ')
      content = CGI::escapeHTML(I18n.t(prefix + i18n_for(name, opts[:ignore_form_context])))
      "<label #{attr_string}>#{content}</label>".html_safe
    end

    def add_tooltip_options(tooltip, options)
      options[:title] = tooltip
      options['data-placement'] = 'bottom'
      options['data-boundary'] = 'viewport'
      options['data-html'] = true
      options['data-delay'] = 500
      options['data-trigger'] = 'manual'
      options['data-template'] = '<div class="tooltip archivesspace-help"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
      options[:class] ||= ''
      options[:class] += ' has-tooltip'
      options
    end

    def button_with_tooltip(tooltip, content, div_classes = [], button_classes = [], use_default_btn_classes = true)
      div_classes = div_classes + ["btn-with-tooltip"]

      button_classes = use_default_btn_classes ? button_classes + ["btn", "btn-sm"] : button_classes

      div_options = {:class => div_classes.join(' ')}
      add_tooltip_options(tooltip, div_options)

      button_options = {:class => button_classes.join(' ')}

      div_attr_string = div_options.map {|k, v| '%s="%s"' % [CGI::escapeHTML(k.to_s),
                                                     CGI::escapeHTML(v.to_s)]}
                           .join(' ')

      button_attr_string = button_options.map {|k, v| '%s="%s"' % [CGI::escapeHTML(k.to_s),
                                                     CGI::escapeHTML(v.to_s)]}
                           .join(' ')

      "<div #{div_attr_string}><button #{button_attr_string}>#{content}</button></div>".html_safe
    end

    def tooltip(name, prefix = '')
      I18n.t_raw("#{prefix}#{i18n_for(name)}_tooltip", :default => '')
    end

    def checkbox(name, opts = {}, default = true, force_checked = false)
      options = {:id => "#{id_for(name)}", :type => "checkbox", :name => path(name), :value => 1}
      options[:checked] = "checked" if force_checked or (obj[name] === true) or (obj[name].is_a? String and obj[name].start_with?("true")) or (obj[name] === "1") or (obj[name].nil? and default)

      @forms.tag("input", options.merge(opts), false, false)
    end

    # takes a JSON representation of the current options selected and the list of archival_record_level enums
    # returns HTML for a set of checkboxes representing current selected and deselected sets for OAI export
    def checkboxes_for_oai_sets(set_json, value_list)
      return "" if value_list == nil
      # when called by #new, set_json will be nil.
      if set_json
        set_arry = JSON::parse(set_json)
      else
        set_arry = []
      end

      html = ""

      html << "<div class='form-group'>"
      html << label("oai_sets_available", {}, ["control-label", "col-sm-2"])
      html << "<div class='col-sm-9'>"
      html << "<ul class='checkbox-list'>"
      value_list['enumeration_values'].each do |v|
        # if we have an empty list of checkboxes, assume all sets are enabled.
        # otherwise, a checkbox is on if it's the in the list we get from the backend.
        checked = set_arry.include?(v['id'].to_s) || set_arry.length == 0

        html << "<li class='list-group-item'>"
        html << "<div class='checkbox'>"
        html << "<label>"
        html << "<input id=\"#{v['id']}\" name=\"sets[#{v['id']}]\" type=\"checkbox\" "
        if checked
          html << "checked=\"checked\" "
        end

        if readonly?
          html << "disabled />"
        else
          html << "/>"
        end # of checkbox tag

        html << "#{v['value']}"
        html << "</label>"
        html << "</div>"
        html << "</li>"
      end
      html << "</ul>"
      html << "</div>" #col-sm-9
      html << "</div>" #form-group

      return html.html_safe
    end

    def oai_config_repo_set_codes_field(set_json, repositories)
      #label_and_textfield(name, opts)
      set_arry = JSON::parse(set_json)

      html = ""

      html << "<div class='form-group row'>"
      html << label("repo_set_section", {}, ["control-label", "col-sm-2"])
      html << "<div class='col-sm-9'>"
      html << "<ul class='checkbox-list'>"
      repositories.each do |r|
        # a checkbox is on if it's the in the list we get from the backend.
        checked = set_arry.include?(r['repo_code'].to_s)

        html << "<li class='list-group-item'>"
        html << "<div class='checkbox'>"
        html << "<label>"
        html << "<input id=\"#{r['repo_code']}\" name=\"repo_set_codes[#{r['repo_code']}]\" type=\"checkbox\" "
        if checked
          html << "checked=\"checked\" "
        end

        html << "/>"

        html << "#{r['repo_code']}"
        html << "</label>"
        html << "</div>"
        html << "</li>"
      end
      html << "</ul>"
      html << "</div>" #col-sm-9
      html << "</div>" #form-group

      return html.html_safe
    end

    def oai_config_sponsor_set_names_field(set_json, opts = {})
      # turn array from DB into a comma delimited list for UI
      set_arry = JSON::parse(set_json)
      value = set_arry.join("|")

      html = ""

      html << "<div class='form-group row'>"
      html << label("sponsor_set_names", {}, ["control-label", "col-sm-2"])
      html << "<div class='col-sm-9'>"
      html << "<input id='oai_config_sponsor_set_names_' type='text' value='#{value}' name='oai_config[sponsor_set_names]' class='form-control js-taggable' datarole='tagsinput'>"
      html << "</div>"
      html << "</div>"

      return html.html_safe
    end

    def merge_checkbox(name, opts = {}, default = false, force_checked = false)
      options = {:id => "#{id_for(name)}", :type => "checkbox", :name => path(name), :value => "REPLACE"}
      options[:checked] = "checked" if force_checked or (obj[name] === true) or (obj[name].is_a? String and obj[name].start_with?("true")) or (obj[name] === "REPLACE") or (obj[name].nil? and default)

      @forms.tag("input", options.merge(opts), false, false)
    end

    def radio(name, value, opts = {})
      options = {:id => "#{id_for(name)}", :type => "radio", :name => path(name), :value => value}
      options[:checked] = "checked" if obj[name] == value

      @forms.tag("input", options.merge(opts), false, false)
    end


    def required?(name)
      if @active_template && @parent.templates[@active_template]
        @parent.templates[@active_template][:definition].required?(name)
      else
        false
      end
    end


    def default_for(name)
      if @active_template && @parent.templates[@active_template]
        @parent.templates[@active_template][:definition].default_for(name)
      else
        nil
      end
    end


    def allowable_types_for(name)
      if @active_template && @parent.templates[@active_template]
        @parent.templates[@active_template][:definition].allowable_types_for(name)
      else
        []
      end
    end


    def possible_options_for(name, add_empty_options = false, opts = {})
      if @active_template && @parent.templates[@active_template]
        @parent.templates[@active_template][:definition].options_for(self, name, add_empty_options, opts)
      else
        []
      end
    end


    def label_with_field(name, field_html, opts = {})
      opts[:label_opts] ||= {}
      opts[:label_opts][:plugin] = opts[:plugin]
      opts[:label_opts][:classes] ||= ''
      opts[:col_size] ||= 9

      control_group_classes,
      label_classes,
      controls_classes = %w(form-group w-100), [], []

      unless opts[:layout] && opts[:layout] == 'stacked'
        control_group_classes.insert(-1, 'row')
        label_classes << "col-sm-#{opts[:label_opts].fetch(:col_size, 2)} #{opts[:label_opts][:classes]}"
        controls_classes << "col-sm-#{opts[:col_size]}"
      end
      # There must be a better way to say this...
      # The value of the 'required' option wins out if set to either true or false
      # if not specified, we take the value of required?
      required = [:required, 'required'].map {|r| opts[r]}.compact.first
      if required.nil?
        required = required?(name)
      end

      # additional admin-defined requirements
      unless required || @required_fields.nil?
        type = @record_type || @context.last[1]["jsonmodel_type"]
        # ideally we would send along the property as well,
        # and be really sure that this field is required on
        # this type of record in such and such context. A possible
        # refactor would be to have all or some of  the marking up
        # of required fields happen on demand (in JavaScript).
        required = @required_fields.required?(nil, type, name)
      end

      control_group_classes << "required" if required == true

      control_group_classes << "conditionally-required" if required == :conditionally

      control_group_classes << "#{opts[:control_class]}" if opts.has_key? :control_class

      #TODO: refactor this. We don't need a separate method for each extra special class to be added below. Probably the thing to is to use the opts param.
      # ANW-617: add JS classes to slug fields
      control_group_classes << "js-slug_textfield" if name == "slug"
      control_group_classes << "js-slug_auto_checkbox" if name == "is_slug_auto"

      # ANW-429: add JS classes to structured date fields
      control_group_classes << "js-structured_date_select" if name == "date_type_structured"

      controls_classes << "#{opts[:controls_class]}" if opts.has_key? :controls_class

      control_group = "<div class=\"#{control_group_classes.join(' ')}\">"
      control_group << label(name, opts[:label_opts], label_classes)
      control_group << "<div class=\"#{controls_classes.join(' ')}\">"
      control_group << field_html
      control_group << "</div>"
      control_group << "</div>"

      # ANW-429
      # TODO: Refactor to the JS files, ideally so this is run when the "Add Date" button is clicked. This is a tricky one since the select field this JS needs to be run on doesn't exist until the callbacks that run after the button is clicked run. Putting it here means that it runs as part of the html, and is always included in the right context.
      control_group << "<script>selectStructuredDateSubform();</script>" if name == "date_type_structured"

      control_group.html_safe
    end

    # ANW-429
    # Generates HTML for a very stripped down summary of a note for use in the agents merge preview.
    # TODO: Eventually we'll want to use the notes partials in place of this code. This code was created because the current notes show takes up a lot of space, and work needs to be done to figure out the exact setup/context needed to get those views to render properly.
    # T
    def notes_preview(notes_index = "notes", content_index = "content")
      content_label = I18n.t("note._frontend.preview.content")
      html = ""

      if obj[notes_index] && obj[notes_index].length > 0

        html << "<div class='subrecord-form-container'>"
        html << "<h4 class='subrecord-form-heading'>#{I18n.t("subsections.notes")}</h4>"

        obj[notes_index].each_with_index do |o, i|
          notes_heading = I18n.t("note.#{o['jsonmodel_type'].to_s}")

          if o[content_index].is_a?(Array)
            notes_content = o[content_index].join(" : ")
          else
            notes_content = o[content_index]
          end

          html << "<section>"
          html << "<h5>#{notes_heading}</h5>"
          html << "<div class='panel panel-default'>"
          html << "<div class=\"form-group\">"
          html << "<label class='control-label col-sm-2'>#{content_label}</label>"
          html << "<div class='col-sm-9 label-only'>"
          html << "#{notes_content}"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</section>"
        end

        html << "</div>"

        html.html_safe

      end
    end

    # Same as above, but intended for use with an agents top level notes record instead of a subrecord, in the merge selector form.
    # Needed because emitting templates as usual breaks the merge selector interface
    def notes_preview_single(obj)
      content_label = I18n.t("note._frontend.preview.content")
      html = ""

      notes_content = ""

      obj['subnotes'].each do |subnote|
        if subnote['jsonmodel_type'] == "note_text"
          notes_content << subnote["content"] if subnote["content"]
        end
      end

      html << "<br />"
      html << "<section>"
      html << "<div class='panel panel-default'>"
      html << "<div class=\"form-group\">"
      html << "<label class='control-label col-sm-2'>#{content_label}</label>"
      html << "<div class='col-sm-9 label-only'>"
      html << "#{notes_content}"
      html << "</div>"
      html << "</div>"
      html << "</div>"
      html << "</section>"

      html.html_safe
    end

    # ANW-429
    # outputs HTML for checkboxes for record-level add and replace for agents merge
    def record_level_merge_controls(form, name = "undefined", controls = true, replace = true, append = true)
      html = ""

      html << '<h4 class="subrecord-form-heading">'
      html << I18n.t("#{name}._singular").to_s

      if controls
        if replace
          html << '<label class="replace-control">'
          html << form.merge_checkbox('replace')
          html << '<small class="fs-14px">'
          html << I18n.t("actions.merge_replace").to_s
          html << '</small>'
          html << '</label>'
        end

        if append
          html << '<label class="append-control">'
          html << form.merge_checkbox('append')
          html << '<small class="fs-14px">'
          html << I18n.t("actions.merge_add").to_s
          html << '</small>'
          html << '</label>'
        end
      end

      html << '</h4>'

      return html.html_safe
    end

  end #of FormContext

  def merge_candidate_view(hash, opts = {})
    jsonmodel_type = hash["jsonmodel_type"]
    schema = JSONModel(jsonmodel_type).schema
    prefix = opts[:plugin] ? 'plugins.' : ''
    html = "<div class='form-horizontal'>"

    hash.reject {|k, v| PROPERTIES_TO_EXCLUDE_FROM_READ_ONLY_VIEW.include?(k)}.each do |property, value|
      if schema and schema["properties"].has_key?(property)
        if (schema["properties"][property].has_key?('dynamic_enum'))
          value = I18n.t("enumerations.#{schema["properties"][property]["dynamic_enum"]}.#{value}", :default => value)
        elsif schema["properties"][property].has_key?("enum")
          value = I18n.t("#{prefix}#{jsonmodel_type.to_s}.#{property}_#{value}", :default => value)
        elsif schema["properties"][property]["type"] === "boolean"
          value = value === true ? "True" : "False"
        elsif schema["properties"][property]["type"] === "date"
          value = value.blank? ? "" : Date.strptime(value, "%Y-%m-%d")
        elsif schema["properties"][property]["type"] === "array"
          # this view doesn't support arrays
          next
        elsif value.is_a? Hash
          # can't display an object either
          next
        end
      end
      value = "" unless value.is_a?(String)
      html << "<div class='form-group'>"
      html << "<div class='control-label col-sm-2'>"
      html << I18n.t("#{prefix}#{jsonmodel_type.to_s}.#{property}")
      html << "</div>"
      html << "<div class='col-sm-8'>#{value}</div>"
      html << "</div>"
    end
    html << "</div>"
    html.html_safe
  end

  class ReadOnlyContext < FormContext

    def readonly?
      true
    end

    def select(name, options, opts = {})
      return nil if obj[name].blank?

      # Attempt a match in the options to give dynamic enums a chance.
      match = options.find {|label, value| value == obj[name]}

      if match
        match[0]
      else
        I18n.t("#{i18n_for(name)}_#{obj[name]}", :default => obj[name])
      end
    end

    def textfield(name = nil, value = "", opts = {})
      return "" if value.blank?
      opts[:escape] = true unless opts[:escape] == false
      opts[:base_url] ||= "/"
      value = clean_mixed_content(value, opts[:base_url]) if opts[:clean] == true
      value = @parent.preserve_newlines(value) if opts[:clean] == true
      value = CGI::escapeHTML(value) if opts[:escape]
      value.html_safe
    end

    def textarea(name = nil, value = "", opts = {})
      return "" if value.blank?
      opts[:escape] = true unless opts[:escape] == false
      opts[:base_url] ||= "/"
      value = clean_mixed_content(value, opts[:base_url]) if opts[:clean] == true
      value = @parent.preserve_newlines(value) if opts[:clean] == true
      value = value.to_s if value.is_a? Integer
      value = CGI::escapeHTML(value) if opts[:escape]
      value.html_safe
    end

    def checkbox(name, opts = {}, default = true, force_checked = false)
      true_i18n = I18n.t("#{i18n_for(name)}_true", :default => I18n.t('boolean.true'))
      false_i18n = I18n.t("#{i18n_for(name)}_false", :default => I18n.t('boolean.false'))
      ((obj[name] === true) || obj[name] === "true") ? true_i18n : false_i18n
    end

    def label_with_field(name, field_html, opts = {})
      return "" if field_html.blank?
      super(name, field_html, opts.merge({:controls_class => ""}))
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
      label_with_field(name, "#{obj[name]}")
    end
  end


  def form_context(name, values_from = {}, &body)
    context = FormContext.new(name, values_from, self)

    env = self.request.env
    env['form_context_depth'] ||= 0
    context.instance_variable_set(:@form_context_depth, env['form_context_depth'])
    # Only fetch required values at the top-level
    if env['form_context_depth'] == 0
      begin
        required_fields = RequiredFields.get(values_from.jsonmodel_type)
        context.instance_variable_set(:@required_fields, required_fields)
      rescue
      end
    end

    s = "<div class=\"form-context\" id=\"form_#{name}\">".html_safe
    s << context.hidden_input("lock_version", values_from["lock_version"])

    env['form_context_depth'] += 1
    s << capture(context, &body)
    env['form_context_depth'] -= 1

    if env['form_context_depth'] == 0
      # Only emit the JS templates at the top-level
      s << templates_for_js(values_from["jsonmodel_type"])
    end
    s << "</div>".html_safe

    s
  rescue
    Rails.logger.error("Failure generating templates for JS: #{$!}")
    Rails.logger.error("Stacktrace:\n%s" % [$@.join("\n")])

    raise $!
  end


  def templates
    @templates ||= {}
    @templates
  end


  class BaseDefinition
    def required?(name)
      false
    end

    def record_type
      nil
    end
  end


  def jsonmodel_definition(type, root = nil)
    JSONModelDefinition.new(JSONModel(type), root)
  end


  class JSONModelDefinition < BaseDefinition
    def initialize(jsonmodel, root)
      @jsonmodel = jsonmodel
      @root = root
    end


    def required?(name)
      ((jsonmodel_schema_definition(name) &&
       jsonmodel_schema_definition(name)['ifmissing'] === 'error'))
    end


    def default_for(name)
      if jsonmodel_schema_definition(name)
        if jsonmodel_schema_definition(name).has_key?('dynamic_enum')
          if jsonmodel_schema_definition(name)['default']
            Rails.logger.warn("Superfluous default value at: #{@jsonmodel}.#{name} ")
          end
          JSONModel.enum_default_value(jsonmodel_schema_definition(name)['dynamic_enum'])
        else
          jsonmodel_schema_definition(name)['default']
        end
      else
        nil
      end
    end


    def allowable_types_for(name)
      defn = jsonmodel_schema_definition(name)

      if defn
        ASUtils.extract_nested_strings(defn).map {|s|
          ref = JSONModel.parse_jsonmodel_ref(s)
          ref.first.to_s if ref
        }.compact
      else
        []
      end
    end


    def options_for(context, property, add_empty_options = false, opts = {})
      options = []
      options.push([(opts[:empty_label] || ""), ""]) if add_empty_options

      defn = jsonmodel_schema_definition(property)

      jsonmodel_enum_for(property).each do |v|
        if opts[:include] && !opts[:include].include?(v)
          next
        end
        if opts[:exclude] && opts[:exclude].include?(v)
          next
        end
        if opts.has_key?(:i18n_path_for) && opts[:i18n_path_for].has_key?(v)
          i18n_path = opts[:i18n_path_for][v]
        elsif opts.has_key?(:i18n_prefix)
          i18n_path = "#{opts[:i18n_prefix]}.#{v}"
        elsif defn.has_key?('dynamic_enum')
          i18n_path = "enumerations.#{defn['dynamic_enum']}.#{v}"
        else
          i18n_path = context.i18n_for("#{Array(property).last}_#{v}")
        end
        options.push([I18n.t(i18n_path, :default => v), v])
      end
      options
    end

    def record_type
      @jsonmodel.record_type
    end

    private

    def jsonmodel_enum_for(property)
      defn = jsonmodel_schema_definition(property)

      if defn["enum"]
        defn["enum"]
      elsif defn["dynamic_enum"]
        JSONModel.enum_values(defn['dynamic_enum'])
      else
        raise "No enum found for #{property}"
      end
    end


    def jsonmodel_schema_definition(property)
      schema = @jsonmodel.schema
      properties = Array(property).clone

      if @root
        properties = [@root] + properties
      end

      while !properties.empty?
        if schema['type'] == 'object'
          schema = schema['properties']
        elsif schema['type'] == 'array'
          schema = schema['items']
        else
          property = properties.shift

          if properties.empty?
            return schema[property]
          else
            schema = schema[property]
          end
        end
      end

      nil
    end

  end

  # we expect the template to be defined in a view context
  # that will have the @required_fields object if applicable.
  # We add it to the template hash because the object will
  # be out of scope when the JS templates are emitted.
  def define_template(name, definition = nil, &block)
    @templates ||= {}
    @templates[name] = {
      :block => block,
      :definition => (definition || BaseDefinition.new),
      :requirements => @required_fields
    }
  end


  def templates_for_js(jsonmodel_type = nil)
    @delivering_js_templates = true

    result = ""
    return result if @templates.blank?

    obj = {}
    obj['jsonmodel_type'] = jsonmodel_type if jsonmodel_type

    templates_to_process = @templates.clone
    templates_processed = []
    # As processing a template may register further templates that hadn't been
    # registered previously, keep looping until we have no more templates to
    # process.
    #
    # Because infinite loops are terrifying and a pain to debug, let us reign
    # in the fear with a 100-loop-count-get-out-of-here-alive limit.
    i = 0
    while (true)
      templates_to_process.each do |name, template|
        context = FormContext.new("${path}", obj, self)

        def context.id_for(name, qualify = true)
          name = path(name) if qualify

          name.gsub(/[\[\]]/, '_').gsub('${path}', '${id_path}')
        end

        context.instance_eval do
          @active_template = name
          @record_type = template[:definition].record_type
          @required_fields = template[:requirements]
        end

        result << "<div id=\"template_#{name}\"><!--"
        result << capture(context, &template[:block])
        result << "--></div>"

        templates_processed << name
      end

      if templates_processed.length < @templates.length
        # some new templates were defined while outputing the js templates
        templates_to_process = @templates.reject {|name, _| templates_processed.include?(name)}
      else
        # we've got them all
        break
      end

      i += 1

      if i > 100
        Rails.logger.error("templates_for_js has looped out more that 100 times")
        break
      end
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

  PROPERTIES_TO_EXCLUDE_FROM_READ_ONLY_VIEW = ["jsonmodel_type", "lock_version", "_resolved", "uri", "ref", "create_time", "system_mtime", "user_mtime", "created_by", "last_modified_by", "sort_name_auto_generate", "suppressed", "display_string", "file_uri", "agent_person_id", "agent_software_id", "agent_family_id", "agent_corporate_entity_id", "id"]

  def read_only_view(hash, opts = {})
    jsonmodel_type = hash["jsonmodel_type"]
    schema = JSONModel(jsonmodel_type).schema
    prefix = opts[:plugin] ? 'plugins.' : ''
    html = "<div class='form-horizontal'>"

    # in some cases, we want to not display certain fields for some records, but not for others.
    # e.g., we don't want to display published for subjects (they are always published), but we do for other records types.
    if opts[:exclude]
      props_to_exclude = PROPERTIES_TO_EXCLUDE_FROM_READ_ONLY_VIEW + opts[:exclude]
    else
      props_to_exclude = PROPERTIES_TO_EXCLUDE_FROM_READ_ONLY_VIEW

    end

    hash.reject {|k, v| props_to_exclude.include?(k)}.each do |property, value|

      if schema and schema["properties"].has_key?(property)
        if (schema["properties"][property].has_key?('dynamic_enum'))
          value = I18n.t("enumerations.#{schema["properties"][property]["dynamic_enum"]}.#{value}", :default => value)
        elsif schema["properties"][property].has_key?("enum")
          value = I18n.t("#{prefix}#{jsonmodel_type.to_s}.#{property}_#{value}", :default => value)
        elsif schema["properties"][property]["type"] === "boolean"
          value = value === true ? I18n.t('boolean.true') : I18n.t('boolean.false')
        elsif schema["properties"][property]["type"] === "date"
          value = value.blank? ? "" : Date.strptime(value, "%Y-%m-%d")
        elsif schema["properties"][property]["type"] === "integer"
          value = value.blank? ? "" : value.to_s
        elsif schema["properties"][property]["type"] === "array"
          # this view doesn't support arrays
          next
        elsif value.is_a? Hash
          # can't display an object either
          next
        end
        next unless value.is_a?(String)
      end

      html << "<div class='form-group d-flex'>"
      html << "<div class='control-label col-sm-2 text-right'>"
      html << I18n.t("#{prefix}#{jsonmodel_type.to_s}.#{property}")
      html << "</div>"
      html << "<div class='col-sm-8'>#{value}</div>"
      html << "</div>"
    end

    html << "</div>"

    html.html_safe
  end

  def preserve_newlines(string)
    string.gsub(/\n/, '<br>')
  end


  def update_monitor_params(record)
    {
      :"data-update-monitor" => true,
      :"data-update-monitor-url" => url_for(:controller => :update_monitor, :action => :poll),
      :"data-update-monitor-record-uri" => record.uri,
      :"data-update-monitor-record-is-stale" => !!@record_is_stale,
      :"data-update-monitor-lock_version" => record.lock_version
    }
  end


  def error_params(exceptions)
    {
      :"data-form-errors" => (exceptions && exceptions.keys[0])
    }
  end

  def custom_report_template_limit_options
    [100, 500, 1000, 5000, 10000, 50000]
  end

  def array_for_textarea(values)
    return values unless values.is_a?(Array)
    values.join("\n")
  end
end
