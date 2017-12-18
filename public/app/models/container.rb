class Container < Record

  def display_string
    bits = []
    if @json['type']
      bits << I18n.t("enumerations.container_type.#{@json['type']}", :default => @json['type'].capitalize)
    end
    bits << @json['indicator']

    bits.join(' ')
  end

end