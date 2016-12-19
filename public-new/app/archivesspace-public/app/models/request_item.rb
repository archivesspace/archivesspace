require 'active_model'

class RequestItem < Struct.new(:user_name, :user_email, :date, :note, :hier, :repo_name, :resource_id,
                           :request_uri, :title, :resource_name, :identifier, :cite, :restrict, :machine, 
                           :top_container_url, :top_container_name,  :barcode, :location_title, :location_url)
  def initialize(hash)
    self.members.each do |sym|
      self[sym] = hash.fetch(sym,nil)
    end
  end
  
  def validate
    errs = []
    errs.push(I18n.t('request.errors.name')) if self[:user_name].blank?
    errs.push(I18n.t('request.errors.email')) if self[:user_email].blank? ||  !self[:user_email].match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i)
    errs
         
              
              
  end
  def to_text(skip_empty = false)
    to_text_array(skip_empty).join("\n")
  end

  def to_text_array(skip_empty = false)
    arr = []
    %i(user_name user_email date note title identifier request_uri resource_name resource_id repo_name hier restrict machine).each do |sym|
      arr.push("#{sym.to_s}: #{self[sym]}") unless skip_empty && self[sym].blank?
    end
    if !self[:top_container_name].blank? &&  !self[:top_container_name].empty?
       self[:top_container_name].each_with_index do |v, i|
        arr.push("#{:top_container_name.to_s}: #{v}")
        %i(top_container_url barcode location_title location_url).each do |sym|
          arr.push("#{sym.to_s}: #{defined?(self[sym][i]) ? self[sym][i] : ''}")
        end
      end
    elsif !skip_empty
      %i(top_container_name top_container_url barcode location_title location_url).each {|sym| arr.push("#{sym.to_s}:") }
    end
    arr
  end
end
