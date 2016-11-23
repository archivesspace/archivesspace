class Search < Struct.new(:q, :op, :field, :limit, :from_year, :to_year, :filter_fields, :filter_values, :filter_from_year, :filter_to_year,:recordtypes, :dates_searched, :sort, :dates_within, :text_within)

  @@BooleanOpts = []

  def Search.get_boolean_opts
    if @@BooleanOpts.empty?
      %w(AND OR NOT).each do |opt|
        @@BooleanOpts.push([ I18n.t("advanced_search.operator.#{opt}"), opt])
      end
    end
    @@BooleanOpts
  end


  # we create all the possible sort options here, then refine them according to what's being sorted
  @@SortOpts = {}

  def Search.get_sort_opts
    if @@SortOpts.empty?
      @@SortOpts['relevance'] = [I18n.t('search_sorting.relevance'), ""]
      # the things we do for I18n!
      %w(title_sort year_sort).each do |type|
        %w(asc desc).each do |dir|
          @@SortOpts["#{type}_#{dir}"] = [I18n.t('search_sorting.sorting', :type => I18n.t("search_sorting.#{type}"), :direction => I18n.t("search_sorting.#{dir}")), "#{type} #{dir}"]
        end
      end
    end
    @@SortOpts
  end


  # We take params either as a Hash or ActionController::Parameters object
  def initialize(params = {})
#    Rails.logger.debug("Initializing: #{params}")
    %w(q op field from_year to_year filter_fields filter_values recordtypes ).each do |f|
      if params.kind_of?(Hash)
         self[f.to_sym] = params[f.to_sym] || []
      else
        self[f.to_sym] = params.fetch(f.to_sym,[])
      end
    end
    %w(limit filter_from_year filter_to_year).each do |f|
      if params.kind_of?(Hash)
        self[f.to_sym] = params[f.to_sym] || ''
      else
        self[f.to_sym] = params.fetch(f.to_sym, '')
      end
    end
    self[:sort] = params.fetch('sort',nil)
    self[:dates_searched] =  have_contents?(from_year) || have_contents?(to_year)
    self[:dates_within] = self[:text_within] = false
  end
 
  def has_query?
    have_contents?(q)
  end
  
  def have_contents?(year_array)
    have = false
    year_array.each do |year|
      unless year.strip == ''
        have = true
      end
    end
    have
  end
 
 def allow_dates?
   allow = true
   limit.split(",").each do |type|
     allow = false if type == 'subject'
     allow = false if type.start_with?('agent')
   end
   allow
 end
 
end
