module ApplicationHelper

  def include_controller_js
    scripts = ""

    scripts += javascript_include_tag "#{controller.controller_name}" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js.erb")

    scripts += javascript_include_tag "#{controller.controller_name}.#{controller.action_name}" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.#{controller.action_name}.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.#{controller.action_name}.js.erb")

    if ["new", "create", "edit", "update"].include?(controller.action_name)
      scripts += javascript_include_tag "#{controller.controller_name}.crud" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.crud.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.crud.js.erb")
    end

    scripts.html_safe
  end

  def include_theme_css
    css = ""
    css += stylesheet_link_tag("themes/#{ArchivesSpace::Application.config.frontend_theme}/bootstrap", :media => "all")
    css += stylesheet_link_tag("themes/#{ArchivesSpace::Application.config.frontend_theme}/application", :media => "all")
    css.html_safe
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

      title = options[:title] || object["title"] || object["username"]

      breadcrumb_trail.push(["#{I18n.t("#{controller.to_s.singularize}._plural")}", {:controller => controller, :action => :index}])

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
        breadcrumb_trail.push([options[:title] || "#{I18n.t("actions.new_prefix")} #{I18n.t("#{type}._singular")}"])
        set_title("#{I18n.t("#{controller.to_s.singularize}._plural")} | #{options[:title] || I18n.t("actions.new_prefix")}")
      end
    elsif options.has_key? :title
        set_title(options[:title])
        breadcrumb_trail.push([options[:title]])
    end

    render(:partial =>"shared/breadcrumb", :layout => false , :locals => { :trail => breadcrumb_trail }).to_s if options[:suppress_breadcrumb] != true
  end

  def render_token(opts)
    popover = "<div class='btn-group'>"
    popover += "<a href='#{root_path}resolve/readonly?uri=#{opts[:uri]}'"
    popover += " target='_blank'" if opts[:inside_token_editor] || opts[:inside_linker_browse]
    popover += " class='btn btn-mini'>#{I18n.t("actions.view")}</a>"
    popover += "</div>"

    popover_template = "<div class='popover token-popover'><div class='arrow'></div><div class='popover-inner'><div class='popover-content'><p></p></div></div></div>"

    html = "<div class='"
    html += "token " if not opts[:inside_token_editor] 
    html += "#{opts[:type]} has-popover' data-trigger='#{opts[:trigger] || "custom"}' data-html='true' data-placement='#{opts[:placement] || "bottom"}' data-content=\"#{CGI.escape_html(popover)}\" data-template=\"#{popover_template}\" tabindex='1'>"
    html += "<span class='icon-token'></span>"
    html += opts[:label]
    html += "</div>"
    html.html_safe
  end

  def link_to_help(opts = {})
    return if not ArchivesSpaceHelp.enabled?
    return if opts.has_key?(:topic) and not ArchivesSpaceHelp.topic?(opts[:topic])

    href = (opts.has_key? :topic) ? ArchivesSpaceHelp.url_for_topic(opts[:topic]) : ArchivesSpaceHelp.base_url

    label = opts[:label] || I18n.t("help.icon")

    title = (opts.has_key? :topic) ? I18n.t("help.topics.#{opts[:topic]}", :default => I18n.t("help.default_tooltip", :default => "")) : I18n.t("help.default_tooltip", :default => "")

    link_to(
            label.html_safe, 
            href, 
            {
              :target => "_blank", 
              :title => title,
              :class => "context-help has-tooltip",
              "data-placement" => "left"
            }.merge(opts[:link_opts] || {})
           )
  end

  def inline?
    params[:inline] === "true"
  end

  def params_for_search(opts = {})
    search_params = {}

    search_params["filter_term"] = Array(opts["filter_term"] || params["filter_term"]).clone
    search_params["filter_term"].concat(Array(opts["add_filter_term"])) if opts["add_filter_term"]
    search_params["filter_term"] = search_params["filter_term"].reject{|f| Array(opts["remove_filter_term"]).include?(f)} if opts["remove_filter_term"]

    search_params["sort"] = opts["sort"] || params["sort"]

    if (opts["format"] || params["format"]).blank?
      search_params.delete("format")
    else
      search_params["format"] =  opts["format"] || params["format"]
    end

    search_params["linker"] = opts["linker"] || params["linker"] || false
    search_params["type"] = opts["type"] || params["type"]
    search_params["facets"] = opts["facets"] || params["facets"]
    search_params["exclude"] = opts["exclude"] || params["exclude"]

    search_params["q"] = opts["q"] || params["q"]

    search_params.reject{|k,v| k.blank? or v.blank?}
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
      options["data-template"] = '<div class="tooltip archivesspace-help"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
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


  def button_delete_action(url)
    button_confirm_action(I18n.t("actions.delete"),
                          url,
                          {
                            :class => "btn btn-small btn-danger delete-record",
                            :"data-title" => I18n.t("actions.delete_confirm_title"),
                            :"data-message" => I18n.t("actions.delete_confirm_message"),
                            :"data-confirm-btn-label" => "#{I18n.t("actions.delete")}",
                            :"data-confirm-btn-class" => "btn-danger"
                          })
  end

end
