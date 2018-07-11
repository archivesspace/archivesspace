require 'nokogiri'
require 'i18n'
require 'asutils'
require_relative 'json_record_spec_helper'
require_relative 'custom_matchers'
require 'jsonmodel'
require 'factory_bot'

if ENV['ASPACE_BACKEND_URL']

  include FactoryBot::Syntax::Methods
  I18n.enforce_available_locales = false # do not require locale to be in available_locales for export
  I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))

  JSONModel::init(:client_mode => true, :strict_mode => true,
                  :url => ENV['ASPACE_BACKEND_URL'],
                  :priority => :high)

  require_relative 'factories.rb'

  auth = JSONModel::HTTP.post_form('/users/admin/login', {:password => 'admin'})
  JSONModel::HTTP.current_backend_session = JSON.parse(auth.body)['session']

  def get_xml(uri)
    uri = URI("#{ENV['ASPACE_BACKEND_URL']}#{uri}")
    response = JSONModel::HTTP::get_response(uri)

    if response.is_a?(Net::HTTPSuccess) || response.status == 200
      Nokogiri::XML::Document.parse(response.body)
    else
      nil
    end
  end

  $repo_record = create(:json_repo)
  $repo_id = $repo_record.id

  JSONModel.set_repository($repo_id)

else
  require_relative 'spec_helper'

  Thread.current[:active_test_user] = User.find(:username => 'admin')

  def get_xml(uri, raw = false)
    response = get(uri)
    if response.status == 200
      if raw
        response.body
      else
        Nokogiri::XML::Document.parse(response.body)
      end
    else
      raise "Invalid response from backend for URI #{uri}: #{response.body}"
    end
  end

end


def get_mets(rec, dmd = "mods")
  get_xml("/repositories/#{$repo_id}/digital_objects/mets/#{rec.id}.xml?dmd=#{dmd}")
end


def get_marc(rec, include_unpublished = true)
  marc = get_xml("/repositories/#{$repo_id}/resources/marc21/#{rec.id}.xml?include_unpublished_marc=#{include_unpublished}")
  marc.instance_eval do
    def df(tag, ind1=nil, ind2=nil)
      selector ="@tag='#{tag}'"
      selector += " and @ind1='#{ind1}'" if ind1
      selector += " and @ind2='#{ind2}'" if ind2
      datafields = self.xpath("//xmlns:datafield[#{selector}]")
      datafields.instance_eval do
        def sf(code)
          self.xpath("xmlns:subfield[@code='#{code}']")
        end
        def sf_t(code)
          sf(code).inner_text
        end
      end

      datafields
    end
  end

  marc
end


def get_mods(rec)
  get_xml("/repositories/#{$repo_id}/digital_objects/mods/#{rec.id}.xml")
end


def get_dc(rec)
  get_xml("/repositories/#{$repo_id}/digital_objects/dublin_core/#{rec.id}.xml")
end

def get_labels(rec)
  get_xml("/repositories/#{$repo_id}/resource_labels/#{rec.id}.tsv", true )
end


def get_eac(rec, repo_id = $repo_id)
  repo_record = JSONModel(:repository).find($repo_id)

  case rec.jsonmodel_type
  when 'agent_person'
    get_xml("/repositories/#{repo_id}/archival_contexts/people/#{rec.id}.xml")
  when 'agent_corporate_entity'
    get_xml("/repositories/#{repo_id}/archival_contexts/corporate_entities/#{rec.id}.xml")
  when 'agent_family'
    get_xml("/repositories/#{repo_id}/archival_contexts/families/#{rec.id}.xml")
  when 'agent_software'
    get_xml("/repositories/#{repo_id}/archival_contexts/softwares/#{rec.id}.xml")
  end
end


def multipart_note_set(publish = true)
  ["accruals", "appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial"].map do |type|
    build(:json_note_multipart, {
            :publish => publish,
            :type => type,
            :subnotes =>  [ build(:json_note_text, :publish => publish) ]
          })
  end
end


def singlepart_note_set(publish = true)
  ["abstract", "physdesc", "langmaterial", "physloc", "materialspec", "physfacet"].map do |type|
    build(:json_note_singlepart, {
            :publish => publish,
            :type => type
          })
  end
end


def full_note_set(publish = true)
  multipart_note_set(publish) + singlepart_note_set(publish)
end


def digital_object_note_set
  ["summary", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "edition", "extent", "altformavail", "originalsloc", "note", "acqinfo", "inscription", "langmaterial", "legalstatus", "physdesc", "prefercite", "processinfo", "relatedmaterial"].map do |type|
    build(:json_note_digital_object, {
            :publish => true,
            :type => type
          })
  end
end

def unpublished_extent_note_set
  ["dimensions", "physdesc"].map do |type|
    build(:json_note_digital_object, {
            :publish => false,
            :type => type
          })
  end
end
