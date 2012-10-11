module AspaceFormHelper
  class FormContext

    def initialize(name, values_from, parent)
      @forms = Object.new
      @parent = parent
      @context = [[name, values_from]]

      class << @forms
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::FormTagHelper
        include ActionView::Helpers::FormOptionsHelper
      end

    end


    def set_index(template, idx)
      template.gsub(/\[\]$/, "[#{idx}]")
    end


    def list_for(objects, context_name, &block)

      objects ||= []
      result = ""

      objects.each_with_index do |object, idx|
        push(set_index(context_name, idx), object) do
          result << @parent.capture(object, &block)
        end
      end

      ("<div data-name-path=\"#{set_index(self.path(context_name), '${index}')}\" " +
       " data-id-path=\"#{id_for(set_index(self.path(context_name), '${index}'), false)}\" " +
       " class=\"subrecord-form-list\">#{result}</div>").html_safe

    end


    def form_top
      @context[0].first
    end


    def id
      "form_#{form_top}"
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
      names = @context.map(&:first)
      tail = names.drop(1)

      path = tail.map {|e|
        e = e.gsub(/\[.*]$/, "")
        "_#{e}"
      }.join(".")

      "#{@active_template or form_top}.#{name}"
    end


    def path_to_i18n_key(path)
      "#{form_top}.#{path.gsub(/\/[0-9]+\//, '.')}"
    end


    def exceptions_for_js(exceptions)
      result = {}

      [:errors, :warnings].each do |condition|
        result[condition] = exceptions[condition].keys.map {|property|
          str = "#{form_top}/#{property}"
          str = str.gsub(/\/([0-9]+)\//, "/[\\1]/")
          str.gsub(/[\[\]\/]/, "_") + "_"
        }
      end

      result.to_json.html_safe
    end


    def id_for(name, qualify = true)
      name = path(name) if qualify

      name.gsub(/[\[\]]/, '_')
    end


    def label_and_textfield(name)
      label_with_field(name, textfield(name, obj[name]))
    end


    def label_and_select(name, options)
      @forms.content_tag(:div, (I18n.t(i18n_for(name)) + @forms.select_tag(path(name), @forms.options_for_select(options))).html_safe)
    end


    def textfield(name = nil, value = "", opts =  {})
      @forms.tag("input", {:id => id_for(name), :type => "text", :value => value, :name => path(name)}.merge(opts),
                 false, false)
    end


    def jsonmodel_enum_for(schema, property)
      JSONModel(schema).schema["properties"][property]["enum"]
    end


    def hidden_input(name, value)
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


    def label_with_field(name, field_html, opts = {})
      control_group_classes = "control-group"
      control_group_classes << " #{opts[:control_class]}" if opts.has_key? :control_class

      control_group = "<div class=\"#{control_group_classes}\">"
      control_group << "<label class=\"control-label\" for=\"#{id_for(name)}\">#{I18n.t(i18n_for(name))}</label>"
      control_group << "<div class=\"controls\">"
      control_group << field_html
      control_group << "</div>"
      control_group << "</div>"
      control_group.html_safe
    end
  end


  def form_context(name, values_from = {}, &body)
    context = FormContext.new(name, values_from, self)

    s = "<div class=\"form-context\" id=\"form_#{name}\">".html_safe
    s << capture(context, &body)
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

end
