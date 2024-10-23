module JSONModelI18nMixin

  def t(*args)
    JSONModel::init_args[:i18n_source].t(args&.[](0), **(args&.[](1) || {}))
  end

  def _exceptions
    exceptions = super

    return exceptions unless JSONModel::init_args[:i18n_source]

    already_translated = exceptions.instance_variable_get(:@translated) || false

    unless already_translated
      [:errors, :warnings].each do |level|
        next unless exceptions[level]
        exceptions[level].clone.each do |path, msgs|
          exceptions[level][path] = msgs.map {|m| translate_exception_message(m, path)}
        end
      end

      exceptions.instance_variable_set(:@translated, true)
    end

    exceptions
  end


  def translate_exception_message(msg, path = nil)
    if path == 'conflicting_record'
      return "<a href='#{AppConfig[:frontend_proxy_url]}/resolve/readonly?uri=#{msg}' target='_blank'>#{t("validation_errors.conflicting_record")}</a>"
    end

    msg_data = case msg
               when "Can't be empty"
                 [:cant_be_empty]
               when "entered value didn't match password"
                 [:password_did_not_match]
               when "Group code must be unique within a repository"
                 [:group_code_already_in_use]
               when "Property is required but was missing"
                 [:missing_required_property]
               when "Property was missing"
                 [:missing_property]
               when "Not a valid date", "not a valid date"
                 [:not_a_valid_date]
               when "is required unless a begin or end date is given"
                 [:is_required_unless_a_begin_or_end_date_is_given]
               when "is required unless an expression or an end date is given"
                 [:is_required_unless_an_expression_or_an_end_date_is_given]
               when "That ID is already in use"
                 [:id_already_in_use]
               when /^Username '(.+)' is already in use/
                 [:username_already_in_use, {:username => $1}]
               when /^Did not match regular expression: (.+)/
                 [:did_not_match_regular_expression, {:regexp => $1}]
               when /^Must be at least ([0-9]+) characters/
                 [:too_few_characters, {:min_length => $1}]
               when /^Must be ([0-9]+) characters or fewer/
                 [:too_many_characters, {:max_length => $1}]
               when /^At least ([0-9]+) item\(s\) is required/
                 [:too_few_items, {:min_items => $1}]
               when /^Invalid value '(.*?)'.  Must be one of: (.*)/
                 [:invalid_value, {:value => $1, :valid_set => $2}]
               when /^Must be a (.*?) \(you provided a (.*)\)/
                 [:wrong_type, {:desired_type => $1, :actual_type => $2}]
               when /^Must be one of: (.*?) \(you provided a (.*)\)/
                 [:must_be_one_of, {:allowed_types => $1, :actual_type => $2}]
               when /Username '(.*)' is already in use/
                 [:username_already_in_use, {:username => $1}]
               else
                 [msg.to_s.downcase.gsub(/[\s,':]/, '_')]
               end

    key, vars = *msg_data
    t("validation_errors.#{key.to_s}", vars)
  end

end
