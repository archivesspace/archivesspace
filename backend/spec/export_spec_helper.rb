require 'nokogiri'
require 'i18n'
require 'asutils'
require_relative 'converter_spec_helper'
require_relative 'custom_matchers'
require 'jsonmodel'
require 'factory_girl'

if ENV['ASPACE_BACKEND_URL']

  include FactoryGirl::Syntax::Methods
  I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))

  JSONModel::init(:client_mode => true, :strict_mode => true,
                  :url => ENV['ASPACE_BACKEND_URL'],
                  :priority => :high)

  load 'factories.rb'

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

  $repo = create(:json_repo)
  $repo_id = $repo.id

  JSONModel.set_repository($repo_id)

else
  require_relative 'spec_helper'

  Thread.current[:active_test_user] = User.find(:username => 'admin')

  def get_xml(uri)
    response = get(uri)
    Nokogiri::XML::Document.parse(response.body)
  end  
end
