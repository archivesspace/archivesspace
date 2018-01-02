require_relative 'spec_helper'
require_relative 'rails_helper'
require 'nokogiri'
  
RSpec.feature "App can be run with a path prefix in a proxy", type: :feature do

  # in this we just check if the URLs are being rewritten to the 
  # url prefix. 
  it "can under a path prefix and all the assets still resolve" do
    allow(JSONModel(:repository)).to receive(:all).and_return( [] )
    allow(JSONModel::HTTP).to receive(:get_json).and_return( {} )
    visit "/"
    doc = Nokogiri::HTML(page.html)  
    
    # check that the CSS is in place 
    doc.css("link").each do |link|
      next if link['href'].include? '.ico' 
      link['href'].should match(/^\/life\//) 
      visit link["href"].gsub(/^\/life/, '')
      page.status_code.should == 200 
    end
    
    # check the JS
    doc.css("script").each do |script|
      next if script["src"].blank?
      script['src'].should match(/^\/life\//) 
      visit script["src"].gsub(/^\/life/, '')
      page.status_code.should == 200 
    end

    doc.to_html.should include('APP_PATH = "/life/";')
    doc.to_html.should include('FRONTEND_URL = "https://aspace.for/life";')

  end
end
