class Container < Record

  def display_string
    bits = []
    if @json['type']
      bits << I18n.t("enumerations.container_type.#{@json['type']}", :default => @json['type'].capitalize)
    end
    bits << @json['indicator']
    if AppConfig[:pui_display_barcodes] && @json['barcode'].present?
      bits << barcode_display_string(@json['barcode'])
    end

    bits.join(' ')
  end

end
