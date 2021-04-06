require 'mixed_content_parser'

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

    elsif jsonmodel_type =~ /lang_material/

      note_types = {
        "langmaterial" => {
          :target => :note_langmaterial,
          :value => "langmaterial",
          :i18n => I18n.t("enumerations._note_types.langmaterial", :default => "langmaterial")
        }
      }

    elsif jsonmodel_type =~ /used_language/

      note_types = {
        "text" => {
          :target => :note_text,
          :value => "text",
          :i18n => I18n.t("note.note_text")
        },
        "citation" => {
          :target => :note_citation,
          :value => "citation",
          :i18n => I18n.t("note.note_citation")
        }
      }

    elsif jsonmodel_type == "agent_contact"

      note_types = {
        "contact_note" => {
          :target => :note_contact_note,
          :value => "contact_note",
          :i18n => I18n.t("note.note_contact_note")
        }
      }

    elsif jsonmodel_type == "agent_place" ||
          jsonmodel_type == "agent_occupation" ||
          jsonmodel_type == "agent_function" ||
          jsonmodel_type == "agent_topic" ||
          jsonmodel_type == "agent_gender"

      note_types = {
        "text" => {
          :target => :note_text,
          :value => "text",
          :i18n => I18n.t("note.note_text")
        },
        "citation" => {
          :target => :note_citation,
          :value => "citation",
          :i18n => I18n.t("note.note_citation")
        }
      }

    elsif jsonmodel_type == "agent_person" ||
          jsonmodel_type == "agent_software"

      note_types = {
        "bioghist" => {
          :target => :note_bioghist,
          :value => "bioghist",
          :i18n => I18n.t("enumerations._note_types.bioghist", :default => "bioghist")
        },
        "general_context" => {
          :target => :note_general_context,
          :value => "general_context",
          :i18n => I18n.t("enumerations._note_types.general_context", :default => "general_context")
        }
      }

    elsif jsonmodel_type == "agent_family"

      note_types = {
        "bioghist" => {
          :target => :note_bioghist,
          :value => "bioghist",
          :i18n => I18n.t("enumerations._note_types.bioghist", :default => "bioghist")
        },
        "general_context" => {
          :target => :note_general_context,
          :value => "general_context",
          :i18n => I18n.t("enumerations._note_types.general_context", :default => "general_context")
        },
        "structure_or_genealogy" => {
          :target => :note_structure_or_genealogy,
          :value => "structure_or_genealogy",
          :i18n => I18n.t("enumerations._note_types.structure_or_genealogy", :default => "structure_or_genealogy")
        }
      }

    elsif jsonmodel_type == "agent_corporate_entity"
      note_types = {
        "bioghist" => {
          :target => :note_bioghist,
          :value => "bioghist",
          :i18n => I18n.t("enumerations._note_types.bioghist", :default => "bioghist")
        },
        "general_context" => {
          :target => :note_general_context,
          :value => "general_context",
          :i18n => I18n.t("enumerations._note_types.general_context", :default => "general_context")
        },
        "mandate" => {
          :target => :note_mandate,
          :value => "mandate",
          :i18n => I18n.t("enumerations._note_types.mandate", :default => "mandate")
        },
        "legal_status" => {
          :target => :note_legal_status,
          :value => "legal_status",
          :i18n => I18n.t("enumerations._note_types.legal_status", :default => "legal_status")
        },
        "structure_or_genealogy" => {
          :target => :note_structure_or_genealogy,
          :value => "structure_or_genealogy",
          :i18n => I18n.t("enumerations._note_types.structure_or_genealogy", :default => "structure_or_genealogy")
        }
      }

    elsif jsonmodel_type == 'rights_statement'

      note_types = {}

      JSONModel.enum_values(JSONModel(:note_rights_statement).schema['properties']['type']['dynamic_enum']).each do |type|
        note_types[type] = {
          :target => :note_rights_statement,
          :enum => JSONModel(:note_rights_statement).schema['properties']['type']['dynamic_enum'],
          :value => type,
          :i18n => I18n.t("enumerations.#{JSONModel(:note_rights_statement).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
        }
      end

    elsif jsonmodel_type == 'rights_statement_act'

      note_types = {}

      JSONModel.enum_values(JSONModel(:note_rights_statement_act).schema['properties']['type']['dynamic_enum']).each do |type|
        note_types[type] = {
          :target => :note_rights_statement_act,
          :enum => JSONModel(:note_rights_statement_act).schema['properties']['type']['dynamic_enum'],
          :value => type,
          :i18n => I18n.t("enumerations.#{JSONModel(:note_rights_statement_act).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
        }
      end

    else

      note_types.merge!(singlepart_notes)
      note_types.merge!(multipart_notes)

      note_types["index"] = {
        :target => :note_index,
        :value => "index",
        :i18n => I18n.t("enumerations._note_types.index", :default => "index")
      }
    end

    note_types
  end


  def singlepart_notes
    note_types = {}

    JSONModel.enum_values(JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum']).each do |type|
      note_types[type] = {
        :target => :note_singlepart,
        :enum => JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum'],
        :value => type,
        :i18n => I18n.t("enumerations.#{JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
      }
    end

    note_types
  end


  def multipart_notes
    note_types = {}

    JSONModel.enum_values(JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum']).each do |type|
      note_types[type] = {
        :target => :note_multipart,
        :enum => JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum'],
        :value => type,
        :i18n => I18n.t("enumerations.#{JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
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

  def general_context_subnotes
    note_types = {}

    JSONModel(:note_general_context).schema['properties']['subnotes']['items']['type'].each do |item_def|
      type = JSONModel.parse_jsonmodel_ref(item_def['type'])[0].to_s
      note_types[type] = {
        :value => type,
        :i18n => I18n.t("#{type}.option", :default => type)
      }
    end

    note_types
  end

  def mandate_subnotes
    note_types = {}

    JSONModel(:note_mandate).schema['properties']['subnotes']['items']['type'].each do |item_def|
      type = JSONModel.parse_jsonmodel_ref(item_def['type'])[0].to_s
      note_types[type] = {
        :value => type,
        :i18n => I18n.t("#{type}.option", :default => type)
      }
    end

    note_types
  end

  def legal_status_subnotes
    note_types = {}

    JSONModel(:note_legal_status).schema['properties']['subnotes']['items']['type'].each do |item_def|
      type = JSONModel.parse_jsonmodel_ref(item_def['type'])[0].to_s
      note_types[type] = {
        :value => type,
        :i18n => I18n.t("#{type}.option", :default => type)
      }
    end

    note_types
  end

  def structure_or_genealogy_subnotes
    note_types = {}

    JSONModel(:note_structure_or_genealogy).schema['properties']['subnotes']['items']['type'].each do |item_def|
      type = JSONModel.parse_jsonmodel_ref(item_def['type'])[0].to_s
      note_types[type] = {
        :value => type,
        :i18n => I18n.t("#{type}.option", :default => type)
      }
    end

    note_types
  end

  def clean_note(note)
    MixedContentParser::parse(note, url_for(:root), :wrap_blocks => true)
  end

end
