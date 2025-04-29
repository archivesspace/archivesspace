require 'mixed_content_parser'

module ApplicationHelper

  def include_controller_js
    scripts = ""

    scripts += javascript_include_tag "#{controller.controller_name}" if File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js") || File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js.erb")

    scripts += javascript_include_tag "#{controller.controller_name}.#{controller.action_name}" if File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.#{controller.action_name}.js") || File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.#{controller.action_name}.js.erb")

    if ["new", "create", "edit", "update"].include?(controller.action_name)
      scripts += javascript_include_tag "#{controller.controller_name}.crud" if File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.crud.js") || File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.crud.js.erb")
    end

    if ["batch_create"].include?(controller.action_name)
      scripts += javascript_include_tag "#{controller.controller_name}.batch" if File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.batch.js") || File.exist?("#{Rails.root}/app/assets/javascripts/#{controller_name}.batch.js.erb")
    end

    if ["defaults", "update_defaults"].include?(controller.action_name)
      ctrl_name = controller.controller_name == 'archival_objects' ? 'resources' : controller.controller_name

      scripts += javascript_include_tag "#{ctrl_name}.crud" if File.exist?("#{Rails.root}/app/assets/javascripts/#{ctrl_name}.crud.js") || File.exist?("#{Rails.root}/app/assets/javascripts/#{ctrl_name}.crud.js.erb")
    end


    scripts.html_safe
  end

  def include_theme_css
    begin
      css = ""
      css += stylesheet_link_tag("themes/#{ArchivesSpace::Application.config.frontend_theme}/bootstrap", :media => "all")
      css += stylesheet_link_tag("themes/#{ArchivesSpace::Application.config.frontend_theme}/application", :media => "all")
      css.html_safe
    rescue
      # On app startup in dev mode, the above call triggers the LESS stylesheets
      # to compile, and there seems to be a problem with two threads doing this
      # concurrently.  If things go badly, just retry.

      Rails.logger.warn("Retrying include_theme_css: #{$!}")

      sleep 1
      retry
    end
  end


  def set_title(title)
    @title = title
  end

  def setup_context(options)
    breadcrumb_trail = options[:trail] || []

    if options.has_key? :object
      object = options[:object]

      type = options[:type] || object["jsonmodel_type"]
      controller = options[:controller] || type.to_s.pluralize

      title = (options[:title] || object["title"] || object["username"]).to_s

      breadcrumb_trail.push([I18n.t("#{controller.to_s.singularize}._plural"), {:controller => controller, :action => :index}])

      if object.id
        breadcrumb_trail.push([title, {:controller => controller, :action => :show}])
        breadcrumb_trail.last.last[:id] = object.id unless object['username']

        if ["edit", "update"].include? action_name
          breadcrumb_trail.push([I18n.t("actions.edit")])
          set_title("#{I18n.t("#{type}._plural")} | #{title} | #{I18n.t("actions.edit")}")
        else
          set_title("#{I18n.t("#{type}._plural")} | #{title}")
        end
      else # new object
        breadcrumb_trail.push([options[:title] || "#{I18n.t("#{type}.new_title")}"])
        set_title("#{I18n.t("#{controller.to_s.singularize}._plural")} | #{options[:title] || I18n.t("actions.new_prefix")}")
      end
    elsif options.has_key? :title
      set_title(options[:title])
      breadcrumb_trail.push([options[:title]])
    end

    render_aspace_partial(:partial =>"shared/breadcrumb", :layout => false , :locals => { :trail => breadcrumb_trail }).to_s if options[:suppress_breadcrumb] != true
  end

  def render_token(opts)
    link_opts = {:class => "btn btn-mini"}
    link_opts.merge!({:target => "_blank"}) if opts[:inside_token_editor] || opts[:inside_linker_browse]
    popover_url = url_for :controller => :resolver, :action => :resolve_readonly
    popover_url += "?uri=#{opts[:uri]}"
    popover_content = link_to I18n.t("actions.view"), popover_url, link_opts

    html = "<div class='"
    html += "token " if not opts[:inside_token_editor]
    html += "#{opts[:type]} has-popover' data-toggle='popover' data-trigger='#{opts[:trigger] || "custom"}' data-html='true' data-placement='#{opts[:placement] || "bottom"}' data-content=\"#{CGI.escape_html(popover_content)}\" tabindex='1'>"

    if opts[:icon_class]
      html += "<span class='icon-token #{opts[:icon_class]}'></span>"
    else
      html += "<span class='icon-token'></span>"
    end
    html += clean_mixed_content(opts[:label])
    html += "</div>"
    html.html_safe
  end

  def link_to_help(opts = {})
    return if not ArchivesSpaceHelp.enabled?
    return if opts.has_key?(:topic) and not ArchivesSpaceHelp.topic?(opts[:topic])

    href = (opts.has_key? :topic) ? ArchivesSpaceHelp.url_for_topic(opts[:topic]) : ArchivesSpaceHelp.base_url

    label = opts[:label] || I18n.t("help.icon")

    label_text = "<span class='sr-only'> Visit the " + I18n.t("help.help_center") + "</span>"

    title = (opts.has_key? :topic) ? I18n.t("help.topics.#{opts[:topic]}", :default => I18n.t("help.default_tooltip", :default => "")) : I18n.t("help.default_tooltip", :default => "")

    x_padding = session[:user].nil? ? "px-4" : "px-3"

    klass = (opts.has_key? :class) ? opts[:class] : ""

    style = (opts.has_key? :style) ? opts[:style] : ""

    link_to(
            label.html_safe + label_text.html_safe,
            href,
            {
              :target => "_blank",
              :title => title,
              :class => "context-help has-tooltip #{x_padding} #{klass}",
              :style => style,
              "data-placement" => "bottom",
              "data-toggle" => "tooltip",
              "data-boundary" => "viewport"
            }.merge(opts[:link_opts] || {})
           )
  end

  def edit_mode?
    ['edit', 'update'].include?(controller.action_name)
  end

  def inline?
    params[:inline] === "true"
  end


  def current_repo
    return nil if session[:repo].blank?
    return @current_repo if @current_repo != nil

    @current_repo = false

    MemoryLeak::Resources.get(:repository).each do |repo|
      @current_repo = repo if repo['uri'] === session[:repo]
    end

    @current_repo
  end


  def job_types
    MemoryLeak::Resources.get(:job_types)
  end


  def current_user
    session[:user]
  end


  def wrap_with_tooltip(text, i18n_path, classes)
    tooltip = I18n.t_raw(i18n_path, :default => '')
    if tooltip.empty?
      return text
    else
      options = {}
      options[:title] = tooltip
      options["data-placement"] = "bottom"
      options["data-html"] = true
      options["data-delay"] = 500
      options["data-trigger"] = "manual"
      options["data-boundary"] = "viewport"
      options["data-template"] = '<div class="tooltip archivesspace-help"><div class="arrow"></div><div class="tooltip-inner"></div></div>'
      options[:class] = " has-tooltip #{classes}"

      content_tag(:span, text, options)
    end
  end


  def button_confirm_action(label, target, opts = {})
    btn_opts = {
      :"data-target" => target,
      :method => :post,
      :class => "btn",
      :"data-confirmation" => true,
      :"data-authenticity_token" => form_authenticity_token,
      :type => "button"
    }.merge(opts)

    button_tag(label, btn_opts)
  end

  def button_get_selector(label, target, opts = {})
    btn_opts = {
      :"data-target" => target,
      :method => :post,
      :class => "btn",
      :"data-confirmation" => true,
      :"data-authenticity_token" => form_authenticity_token,
      :type => "button"
    }.merge(opts)
    button_tag(label, btn_opts)
  end

  def button_delete_action(url, opts = {})
    button_confirm_action(opts[:label] || I18n.t("actions.delete"),
                          url,
                          {
                            :class => "btn btn-sm btn-danger delete-record",
                            :"data-title" => I18n.t("actions.delete_confirm_title"),
                            :"data-message" => I18n.t("actions.delete_confirm_message"),
                            :"data-confirm-btn-label" => "#{I18n.t("actions.delete")}",
                            :"data-confirm-btn-class" => "btn-danger"
                          }.merge(opts))
  end


  def button_delete_multiple_action(target_action)
    button_delete_action(url_for(:controller => :batch_delete, :action => target_action), {
      :class => "btn btn-sm btn-danger multiselect-enabled",
      :"data-multiselect" => "#tabledSearchResults",
      :"data-title" => I18n.t("actions.delete_multiple_confirm_title"),
      :"data-message" => I18n.t("actions.delete_multiple_confirm_message"),
      :"data-confirm-btn-label" => "#{I18n.t("actions.delete_multiple")}",
      :disabled => "disabled"
    })
  end

  def button_edit_multiple_action(target_controller, target_action = :batch, opts = {} )
    label = opts[:label] || I18n.t("actions.edit_batch")
    btn_opts = {
      :"data-target" => url_for(:controller => target_controller, :action => target_action),
      :class => "btn btn-sm btn-default multiselect-enabled edit-batch",
      :method => "post",
      :type => "button",
      :"data-multiselect" => "#tabledSearchResults",
      :"data-confirmation" => true,
      :"data-title" => I18n.t("actions.edit_multiple_confirm_title"),
      :"data-message" => I18n.t("actions.edit_multiple_confirm_message"),
      :"data-confirm-btn-label" => "#{I18n.t("actions.edit_multiple")}",
      :"data-authenticity_token" => form_authenticity_token,
      :disabled => "disabled"
    }.merge(opts)

    button_tag(label, btn_opts)
  end

  def display_audit_info(hash, opts = {})
    fmt = opts[:format] || 'wide'
    ark_url = nil
    if AppConfig[:arks_enabled] && hash['ark_name']
      # watch out! hash might be from a jsonmodel or from a solr result
      # don't blame me, i'm just trying to fit in around here
      ark_url = if hash["ark_name"].is_a?(Array)
                  hash["ark_name"].first
                else
                  hash["ark_name"]["current"]
                end
    end
    html = "<div class='audit-display-#{fmt}'><small>"
    if hash['create_time'] and hash['user_mtime']
      if fmt == 'wide'
        html << "<strong>#{I18n.t("search_results.created")} #{hash['created_by']}</strong>"
        html << " #{Time.parse(hash['create_time']).getlocal}"
        html << ' | '
        html << "<strong>#{I18n.t("search_results.modified")} #{hash['last_modified_by']}</strong>"
        html << " #{Time.parse(hash['user_mtime']).getlocal}"
        html << ' | '
        html << "<label for=\"uri\"><strong>URI:</strong> </label>"
        html << "<input type=\"text\" id=\"uri\" readonly=\"1\" value=\"#{hash['uri']}\" size=\"#{hash['uri'].length}\" style=\"background: #f1f1f1 !important; border: none !important; font-family: monospace;\"/>"
        if !ark_url.nil?
          html << ' | '
          html << "<label for=\"ark\"><strong>ARK:</strong> </label>"
          html << "<input type=\"text\" id=\"ark\" readonly=\"1\" value=\"#{ark_url}\" size=\"#{ark_url.length}\" style=\"background: #f1f1f1 !important; border: none !important; font-family: monospace;\"/>"
        end
      else
        html << "<dl>"
        html << "<dt>#{I18n.t("search_results.created")} #{hash['created_by']}</dt>"
        html << "<dd>#{Time.parse(hash['create_time']).getlocal}</dd>"
        html << "<dt>#{I18n.t("search_results.modified")} #{hash['last_modified_by']}</dt>"
        html << "<dd>#{Time.parse(hash['user_mtime']).getlocal}</dd>"
        html << "</dl>"
      end
    end
    html << "</small></div><div class='clearfix'></div>"
    html.html_safe
  end


  def has_permission_for_controller?(session, name)
    controller_class_name = "#{name}_controller".classify
    controller_class = Kernel.const_get(controller_class_name)

    controller_class.can_access?(self, :index)
  end


  # See: ApplicationController#render_aspace_partial
  def render_aspace_partial(args)
    defaults = {:formats => [:html], :handlers => [:erb]}
    return render(defaults.merge(args))
  end

  def clean_mixed_content(content)
    content = content.to_s
    return content if content.blank?
    MixedContentParser::parse(content, url_for(:root), { :wrap_blocks => false } ).to_s.html_safe
  end

  def proxy_localhost?
    AppConfig[:public_proxy_url] =~ /localhost/
  end

  def add_new_event_url(record)
    if record.jsonmodel_type == "agent"
      url_for(:controller => :events, :action => :new, :agent_uri => record.uri,  :event_type => "${event_type")
    else
      url_for(:controller => :events, :action => :new, :record_uri => record.uri, :record_type => record.jsonmodel_type, :event_type => "${event_type}")
    end
  end

  def show_external_ids?
    AppConfig[:show_external_ids] == true
  end

  def export_csv(search_data)
    results = search_data["results"]

    headers = results.inject([]) { |h, r| h | r.keys }
    headers.delete("json")

    CSV.generate do |csv|
      csv << headers
      results.each do |result|
        data = []
        headers.each do |h|
          unless result.include?(h)
            data << nil
            next
          end
          v = result[h]
          v = v.join(";") if v.is_a?(Array)
          v = v.to_s
          v.gsub!('\"', '""')
          v.delete!("\n")
          v.delete!(",")
          data << v
        end
        csv << data
      end
    end
  end

  # Merge new_params into params and generate a link.
  #
  # Intended to avoid security issues associated with passing user-generated
  # `params` as the `opts` for link_to (which allows them to set the host,
  # controller, etc.)
  def link_to_merge_params(label, new_params, html_options = {})
    link_to(label,
            params.except(:controller, :action).to_unsafe_h.merge(new_params),
            html_options)
  end

  # ANW-521: given an object, if it is a subject, return the class needed to display the correct icon in the interface
  def get_subject_icon_class(obj)
    if obj['_resolved']
      if obj['_resolved']['jsonmodel_type'] &&
         obj['_resolved']['jsonmodel_type'] == "subject"

        term_type = obj['_resolved']['terms'][0]["term_type"] rescue nil

        case term_type
        when "cultural_context"
          return "subject_type_cultural_context"
        when "function"
          return "subject_type_function"
        when "genre_form"
          return "subject_type_genre_form"
        when "geographic"
          return "subject_type_geographic"
        when "occupation"
          return "subject_type_occupation"
        when "style_period"
          return "subject_type_style_period"
        when "technique"
          return "subject_type_technique"
        when "temporal"
          return "subject_type_temporal"
        when "topical"
          return "subject_type_topical"
        when "uniform_title"
          return "subject_type_uniform_title"
        end
      end
    end
  end

  def supported_locales_default
    {
      default: user_prefs.key?('locale') ? user_prefs['locale'] : I18n.default_locale.to_s
    }
  end

  def supported_locales_options
    I18n.supported_locales.map { |k, v| [t("enumerations.language_iso639_2.#{v}"), k] }
  end

  def full_mode?
    user_can?("show_full_agents") || user_can?("administer_system")
  end

  def has_agent_subrecords?(agent)
    # agent_person has all agent subrecord types so is ideal for finding any potential subrecord
    JSONModel(:agent_person).properties_by_tag('agent_subrecord').map(&:first).map(&:to_sym).find do |subrecord|
      return unless agent.methods.include?(subrecord)
      agent.send(subrecord).length.positive?
    end
  end
end
