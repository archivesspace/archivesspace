  class DigitalObjectHandler < Handler
    @@digital_object_types ||= CvList.new('digital_object_digital_object_type')
    
    def self.create(row, archival_object, report)
      dig_o = nil
      dig_instance = nil
      thumb = row['thumbnail'] || row['Thumbnail']
      unless !thumb && !row['digital_object_link']
        files = []
        if !row['digital_object_link'].blank? && row['digital_object_link'].start_with?('http')
          fv = JSONModel(:file_version).new._always_valid!
          fv.file_uri = row['digital_object_link']
          fv.publish = row['publish']
          fv.xlink_actuate_attribute = 'onRequest'
          fv.xlink_show_attribute = 'new'
          files.push fv
        end
        if !thumb.blank? && thumb.start_with?('http')
          fv = JSONModel(:file_version).new._always_valid!
          fv.file_uri = thumb
          fv.publish = row['publish']
          fv.xlink_actuate_attribute = 'onLoad'
          fv.xlink_show_attribute = 'embed'
          fv.is_representative = true
          files.push fv
        end
        osn = row['digital_object_id'].blank? ? (archival_object.ref_id + 'd') : row['digital_object_id']
        dig_o = JSONModel(:digital_object).new._always_valid!
        dig_o.title = row['digital_object_title'].blank? ? archival_object.display_string : row['digital_object_title']
        dig_o.digital_object_id = osn
        dig_o.file_versions = files
        dig_o.publish = row['publish']
        begin
          dig_o.save
        rescue ValidationException => ve
          report.add_errors(I18n.t('plugins.aspace-import-excel.error.dig_validation', :err => ve.errors))
          return  nil
        rescue Exception => e
          raise e
        end
        report.add_info(I18n.t('plugins.aspace-import-excel.created', :what =>I18n.t('plugins.aspace-import-excel.dig'), :id => "'#{dig_o.title}' #{dig_o.uri} [#{dig_o.digital_object_id}]"))
        dig_instance = JSONModel(:instance).new._always_valid!
        dig_instance.instance_type = 'digital_object'
        dig_instance.digital_object = {"ref" => dig_o.uri}
      end
      dig_instance
    end

    def self.renew
      clear(@@digital_object_types)
    end
  end  # DigitalObjectHandler

