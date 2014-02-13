require 'nokogiri'
require 'i18n'
require 'asutils'
require_relative 'converter_spec_helper'

if ENV['ASPACE_BACKEND_URL']
  require_relative 'custom_matchers'
  require 'jsonmodel'

  JSONModel::init(:client_mode => true, :strict_mode => true,
                  :url => ENV['ASPACE_BACKEND_URL'],
                  :priority => :high)

  auth = JSONModel::HTTP.post_form('/users/admin/login', {:password => 'admin'})
  JSONModel::HTTP.current_backend_session = JSON.parse(auth.body)['session']

  require 'factory_girl'
  require_relative 'factories'
  include FactoryGirl::Syntax::Methods

  
  I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))


  def get_xml(uri)
    uri = URI("#{ENV['ASPACE_BACKEND_URL']}#{uri}")
    response = JSONModel::HTTP::get_response(uri)

    if response.is_a?(Net::HTTPSuccess) || response.status == 200
      Nokogiri::XML::Document.parse(response.body)
    else
      nil
    end
  end

  $repo = create(:json_repo)
  $repo_id = $repo.id

  JSONModel.set_repository($repo_id)

else
  require 'spec_helper'

  # $old_user = Thread.current[:active_test_user]
  Thread.current[:active_test_user] = User.find(:username => 'admin')

  def get_xml(uri)
    response = get(uri)
    Nokogiri::XML::Document.parse(response.body)
  end  
end


def get_marc(rec)
  get_xml("/repositories/#{$repo_id}/resources/marc21/#{rec.id}.xml")
end


describe 'MARC Export' do

  describe "datafield 110 name mapping" do

    before(:all) do
      @name = build(:json_name_corporate_entity)
      agent = create(:json_agent_corporate_entity,
                    :names => [@name])
      @resource = create(:json_resource,
                         :linked_agents => [
                                            {
                                              'role' => 'creator',
                                              'ref' => agent.uri
                                            }
                                           ]
                         )

      @marc = get_marc(@resource)

      # puts "SOURCE: #{@resource.inspect}"
      # puts "RESULT: #{@marc.to_xml}"
    end

    it "maps primary_name to subfield 'a'" do
      @marc.should have_tag "datafield[@tag='110']/subfield[@code='a']" => @name.primary_name
    end
  end


  describe "datafield 245 mapping" do
    before(:all) do

      @dates = ['inclusive', 'bulk'].map {|type|
        range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
        build(:json_date,
              :date_type => type,
              :begin => range[0],
              :end => range[1],
              :expression => [true, false].sample ? generate(:string) : nil
              )
      }

      2.times { @dates << build(:json_date) }


      @resource = create(:json_resource,
                         :dates => @dates)

      @marc = get_marc(@resource)

      # puts "SOURCE: #{@resource.inspect}"
      # puts "RESULT: #{@marc.to_xml}"
    end

    it "maps the first inclusive date to subfield 'f'" do
      date = @dates.find{|d| d.date_type == 'inclusive'}
      
      if date.expression
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.expression}"
      else
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.begin} - #{date.end}"
      end
    end


    it "maps the first bulk date to subfield 'g'" do
      date = @dates.find{|d| d.date_type == 'bulk'}
      @marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{date.begin} - #{date.end}"
    end


    it "doesn't create more than two dates" do
      %w(f g).each do |code|
        @marc.should_not have_tag "datafield[@tag='245']/subfield[@code='#{code}'][2]"
      end
    end
  end


  describe "datafield 3xx mapping" do
    before(:all) do

      @notes = %w(arrangement fileplan).map { |type|
        build(:json_note_multipart,
              :type => type)
      }

      @extents = (0..5).to_a.map{ build(:json_extent) }
      @resource = create(:json_resource,
                         :extents => @extents,
                         :notes => @notes)

      @marc = get_marc(@resource)

      # puts "SOURCE: #{@resource.inspect}"
      # puts "RESULT: #{@marc.to_xml}"
    end

    it "creates a 300 field for each extent" do
      @marc.should have_tag "datafield[@tag='300'][#{@extents.count}]"
      @marc.should_not have_tag "datafield[@tag='300'][#{@extents.count + 1}]"
    end


    it "maps extent number and type to subfield a" do
      type = I18n.t("enumerations.extent_extent_type.#{@extents[0].extent_type}")
      extent = "#{@extents[0].number} #{type}"
      @marc.should have_tag "datafield[@tag='300'][1]/subfield[@code='a']" => extent
    end


    it "maps container summary to subfield f" do
      @extents.each do |e|
        next unless e.container_summary
        @marc.should have_tag "datafield[@tag='300']/subfield[@code='f']" => e.container_summary
      end
    end


    it "maps arrangment and fileplan notes to datafield 351" do
      @notes.each do |note|
        @marc.should have_tag "datafield[@tag='351']/subfield[@code='b'][1]" => note_content(note)
      end
    end
  end    
end
