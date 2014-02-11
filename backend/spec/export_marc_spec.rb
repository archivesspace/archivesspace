require 'nokogiri'

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

      puts "SOURCE: #{@resource.inspect}"
      puts "RESULT: #{@marc.to_xml}"
    end

    it "maps primary_name to subfield 'a'" do
      @marc.should have_tag "datafield[@tag='110']/subfield[@code='a']" => @name.primary_name
    end
  end


  describe "datafield 245 mapping" do
    before(:all) do
      @date = build(:json_date,
                    :date_type => 'inclusive',
                    :begin => '1900',
                    :end => '2000'
                    )

      @resource = create(:json_resource,
                         :dates => [@date])

      @marc = get_marc(@resource)
    end

    it "maps an inclusive date to subfield 'f'" do
      @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{@date.begin} - #{@date.end}"
    end
    

  end
end
