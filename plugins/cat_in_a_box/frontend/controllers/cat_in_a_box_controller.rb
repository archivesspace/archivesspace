require 'open-uri'
require 'nokogiri'

class CatInABoxController < ApplicationController

  skip_before_filter :unauthorised_access
 
  def index
    c = Nokogiri::XML(open('http://thecatapi.com/api/images/get?format=xml&category=boxes'))
    @cat = {}
    c.at_xpath('//image').elements.each { |n| @cat[n.name.to_sym] = n.inner_text }
  end

end