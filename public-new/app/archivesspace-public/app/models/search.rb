class Search < Struct.new(:q, :op, :field, :limit, :from_year, :to_year, :filter_fields, :filter_values, :filter_from_year, :filter_to_year, :dates_searched)

@@BooleanOpts = []

  def Search.get_boolean_opts
    if @@BooleanOpts.empty?
      %w(AND OR NOT).each do |opt|
        @@BooleanOpts.push([ I18n.t("advanced_search.operator.#{opt}"), opt])
      end
    end
    @@BooleanOpts
  end

  def initialize(params)
    %w(q op field from_year to_year filter_fields filter_values ).each do |f|
      self[f.to_sym] = params.fetch(f.to_sym,[])
    end
    %w(limit filter_from_year filter_to_year).each do |f|
      self[f.to_sym] = params.fetch(f.to_sym, '')
    end
    self[:dates_searched] =  have_contents?(from_year) || have_contents?(to_year)
    self[:q] = nil unless have_contents?(q)
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

end
