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

      breadcrumb_trail.push(["#{I18n.t("#{controller.to_s.singularize}._html.plural")}", {:controller => controller, :action => :index}])

      if object.id
        breadcrumb_trail.push([title, {:controller => controller, :action => :show}])
        breadcrumb_trail.last.last[:id] = object.id unless object['username']

        if ["edit", "update"].include? action_name
          breadcrumb_trail.push([I18n.t("actions.edit")])
          set_title("#{I18n.t("#{type}._html.plural")} | #{title} | #{I18n.t("actions.edit")}")
        else
          set_title("#{I18n.t("#{type}._html.plural")} | #{title}")
        end
      else # new object
        breadcrumb_trail.push([options[:title] || "#{I18n.t("actions.new_prefix")} #{I18n.t("#{type}._html.singular")}"])
        set_title("#{I18n.t("#{controller.to_s.singularize}._html.plural")} | #{options[:title] || I18n.t("actions.new_prefix")}")
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

    search_params["filter"] = Array(params["filter"]).clone

    if opts["add_filter"]
      search_params["filter"].concat(Array(opts["add_filter"]))
    end

    if opts["remove_filter"]
      search_params["filter"] = search_params["filter"].reject{|f| Array(opts["remove_filter"]).include?(f)}
    end

    search_params["sort"] = opts["sort"] || params["sort"]

    search_params["q"] = opts["q"] || params["q"]

    search_params
  end

  def current_repo
    return nil if session[:repo].blank?

    MemoryLeak::Resources.get(:repository).each do |repo|
      return repo if repo['uri'] === session[:repo]
    end

    nil
  end

end
