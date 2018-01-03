require 'factory_bot'

module FactoryBotSyntaxHelpers

  def sample(enum, exclude = [])
    values = if enum.has_key?('enum')
               enum['enum']
             elsif enum.has_key?('dynamic_enum')
               enum_source.values_for(enum['dynamic_enum'])
             else
               raise "Not sure how to sample this: #{enum.inspect}"
             end

    exclude += ['other_unmapped']

    values.reject{|i| exclude.include?(i) }.sample
  end


  def enum_source
    if defined? BackendEnumSource
      BackendEnumSource
    else
      JSONModel.init_args[:enum_source]
    end
  end


  def JSONModel(key)
    JSONModel::JSONModel(key)
  end


  def nil_or_whatever
    [nil, FactoryBot.generate(:alphanumstr)].sample
  end


  def few_or_none(key)
    arr = []
    rand(4).times { arr << build(key) }
    arr
  end
end

FactoryBot::SyntaxRunner.send(:include, FactoryBotSyntaxHelpers)
FactoryBot::Syntax::Default::DSL.send(:include, FactoryBotSyntaxHelpers)


FactoryBot.define do

  sequence(:alphanumstr) { (0..4).map{ rand(3)==1?rand(1000):(65 + rand(25)).chr }.join }
  sequence(:number) { rand(100).to_s }

  sequence(:agent_role) { sample(JSONModel(:event).schema['properties']['linked_agents']['items']['properties']['role']) }
  sequence(:record_role) { sample(JSONModel(:event).schema['properties']['linked_records']['items']['properties']['role']) }

  sequence(:date_type) { sample(JSONModel(:date).schema['properties']['date_type']) }
  sequence(:date_lable) { sample(JSONModel(:date).schema['properties']['label']) }

  sequence(:multipart_note_type) { sample(JSONModel(:note_multipart).schema['properties']['type'])}
  sequence(:digital_object_note_type) { sample(JSONModel(:note_digital_object).schema['properties']['type'])}
  sequence(:rights_statement_note_type) { sample(JSONModel(:note_rights_statement).schema['properties']['type'])}
  sequence(:rights_statement_act_note_type) { sample(JSONModel(:note_rights_statement_act).schema['properties']['type'])}
  sequence(:singlepart_note_type) { sample(JSONModel(:note_singlepart).schema['properties']['type'])}
  sequence(:note_index_type) { sample(JSONModel(:note_index).schema['properties']['type'])}
  sequence(:note_index_item_type) { sample(JSONModel(:note_index_item).schema['properties']['type'])}
  sequence(:note_bibliography_type) { sample(JSONModel(:note_bibliography).schema['properties']['type'])}
  sequence(:orderedlist_enumeration) { sample(JSONModel(:note_orderedlist).schema['properties']['enumeration']) }
  sequence(:chronology_item) { {'event_date' => nil_or_whatever, 'events' => (0..rand(3)).map { FactoryBot.generate(:alphanumstr) } } }

  sequence(:event_type) { sample(JSONModel(:event).schema['properties']['event_type']) }
  sequence(:extent_type) { sample(JSONModel(:extent).schema['properties']['extent_type']) }
  sequence(:portion) { sample(JSONModel(:extent).schema['properties']['portion']) }
  sequence(:instance_type) { sample(JSONModel(:instance).schema['properties']['instance_type'], ['digital_object']) }

  sequence(:rights_type) { sample(JSONModel(:rights_statement).schema['properties']['rights_type']) }
  sequence(:status) { sample(JSONModel(:rights_statement).schema['properties']['status']) }
  sequence(:jurisdiction) { sample(JSONModel(:rights_statement).schema['properties']['jurisdiction']) }
  sequence(:other_rights_basis) { sample(JSONModel(:rights_statement).schema['properties']['other_rights_basis']) }
  sequence(:act_type) { sample(JSONModel(:rights_statement_act).schema['properties']['act_type']) }
  sequence(:act_restriction) { sample(JSONModel(:rights_statement_act).schema['properties']['restriction']) }
  sequence(:external_document_identifier_type) { sample(JSONModel(:rights_statement_external_document).schema['properties']['identifier_type']) }

  sequence(:container_location_status) { sample(JSONModel(:container_location).schema['properties']['status']) }
  sequence(:temporary_location_type) { sample(JSONModel(:location).schema['properties']['temporary']) }

  sequence(:use_statement) { sample(JSONModel(:file_version).schema['properties']['use_statement']) }
  sequence(:checksum_method) { sample(JSONModel(:file_version).schema['properties']['checksum_method']) }
  sequence(:xlink_actuate_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_actuate_attribute']) }
  sequence(:xlink_show_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_show_attribute']) }
  sequence(:file_format_name) { sample(JSONModel(:file_version).schema['properties']['file_format_name']) }
  sequence(:language) { sample(JSONModel(:resource).schema['properties']['language']) }
  sequence(:archival_record_level) { sample(JSONModel(:resource).schema['properties']['level'], ['otherlevel']) }
  sequence(:finding_aid_description_rules) { sample(JSONModel(:resource).schema['properties']['finding_aid_description_rules']) }

  sequence(:relator) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['relator']) }
  sequence(:subject_source) { sample(JSONModel(:subject).schema['properties']['source']) }
  sequence(:resource_agent_role) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['role']) }

  sequence(:vocab_name) {|n| "Vocabulary #{n} - #{Time.now}" }
  sequence(:vocab_refid) {|n| "vocab_ref_#{n} - #{Time.now}"}

  sequence(:downtown_address) { "#{rand(200)} #{%w(E W).sample} #{(4..9).to_a.sample}th Street" }

  sequence(:name_rule) { sample(JSONModel(:abstract_name).schema['properties']['rules']) }
  sequence(:name_source) { sample(JSONModel(:abstract_name).schema['properties']['source']) }

  sequence(:generic_name) {|n| "Name Number #{n}"}
  sequence(:sort_name) { |n| "SORT #{('a'..'z').to_a[rand(26)]} - #{n}" }

  sequence(:term) { |n| "Term #{n}" }
  sequence(:term_type) { sample(JSONModel(:term).schema['properties']['term_type']) }

  sequence(:url) {|n| "http://www.example-#{n}.com"}
end
