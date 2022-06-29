module ErrorsHelper
  def transfer_errors_by_message(transfer_errors)
    results = {}
    transfer_errors.each do |uri, errors|
      errors.each do |err|
        next unless err['message']
        results[err['message']] ||= {}
        results[err['message']][uri] = err
      end
    end
    results.transform_keys { |k|
      case k
      when 'DIGITAL_OBJECT_IN_USE'
        I18n.t('actions.transfer_failed_records_using_digital_objects')
      when 'DIGITAL_OBJECT_HAS_LINK'
        I18n.t('actions.transfer_failed_digital_objects_linked_to_records')
      when 'TOP_CONTAINER_IN_USE'
        I18n.t('actions.transfer_failed_top_containers_in_use')
      when 'BARCODE_IN_USE'
        I18n.t('actions.transfer_failed_barcodes_in_use')
      else
        k
      end
    }
  end
end
