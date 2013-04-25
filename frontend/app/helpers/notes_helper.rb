module NotesHelper

  def note_types_for(jsonmodel_type)
    note_types = {
      "bibliography" => {
        :target => :note_bibliography,
        :value => "bibliography",
        :i18n => I18n.t("enumerations._note_types.bibliography", :default => "bibliography")
      }
    }

    if jsonmodel_type =~ /digital_object/

      # Digital object/digital object component
      JSONModel.enum_values(JSONModel(:note_digital_object).schema['properties']['type']['dynamic_enum']).each do |type|
        note_types[type] = {
          :target => :note_digital_object,
          :enum => JSONModel(:note_digital_object).schema['properties']['type']['dynamic_enum'],
          :value => type,
          :i18n => I18n.t("enumerations.#{JSONModel(:note_digital_object).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
        }
      end

    elsif jsonmodel_type =~ /agent/

      note_types = {"bioghist" => {
          :target => :note_bioghist,
          :value => "bioghist",
          :i18n => I18n.t("enumerations._note_types.bioghist", :default => "bioghist")
        }
      }

    else

      # Resource/AO
      JSONModel.enum_values(JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum']).each do |type|
        note_types[type] = {
          :target => :note_singlepart,
          :enum => JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum'],
          :value => type,
          :i18n => I18n.t("enumerations.#{JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
        }
      end

      JSONModel.enum_values(JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum']).each do |type|
        note_types[type] = {
          :target => :note_multipart,
          :enum => JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum'],
          :value => type,
          :i18n => I18n.t("enumerations.#{JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
        }
      end

      note_types["index"] = {
        :target => :note_index,
        :value => "index",
        :i18n => I18n.t("enumerations._note_types.index", :default => "index")
      }
    end

    note_types
  end


  def multipart_subnotes
    note_types = {}

    JSONModel(:note_multipart).schema['properties']['subnotes']['items']['type'].each do |item_def|
      type = JSONModel.parse_jsonmodel_ref(item_def['type'])[0].to_s
      note_types[type] = {
        :value => type,
        :i18n => I18n.t("#{type}.option", :default => type)
      }
    end

    note_types
  end


  def bioghist_subnotes
    note_types = {}

    JSONModel(:note_bioghist).schema['properties']['subnotes']['items']['type'].each do |item_def|
      type = JSONModel.parse_jsonmodel_ref(item_def['type'])[0].to_s
      note_types[type] = {
        :value => type,
        :i18n => I18n.t("#{type}.option", :default => type)
      }
    end

    note_types
  end

end
