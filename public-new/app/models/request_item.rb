require 'active_model'

class RequestItem < Struct.new(:user_name, :user_email, :date, :note, :hierarchy, :repo_name, :resource_id,
                               :request_uri, :title, :resource_name, :identifier, :cite, :restrict,
                               :restriction_ends,  :machine, 
                               :top_container_url, :container,  :barcode, :location_title, 
                               :location_url)

  def RequestItem.allow_nontops(repo_code)
    allow = nil
    rep_allow = nil
    begin
      rep_allow  = AppConfig[:repos].dig(repo_code.downcase,:requests_permitted_for_containers_only) if repo_code
      allow = !rep_allow unless rep_allow.nil?
    rescue Exception => err
      raise err unless err.message.start_with?("No value set for config parameter")
    end
    allow = !AppConfig[:requests_permitted_for_containers_only] if allow.nil?
    Rails.logger.debug("allow? #{ allow}")
    allow
  end

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
    %i(user_name user_email date note title identifier cite request_uri resource_name resource_id repo_name hierarchy restrict restriction_ends).each do |sym|
      arr.push("#{sym.to_s}: #{self[sym]}") unless skip_empty && self[sym].blank?
    end
    arr.push("machine: #{self[:machine].blank? ? '' : self[:machine].join(', ')}")
    if !self[:container].blank? &&  !self[:container].empty?
       self[:container].each_with_index do |v, i|
#        arr.push("#{:container.to_s}: #{v}")
        %i(container top_container_url barcode location_title location_url).each do |sym|
          arr.push("#{sym.to_s}: #{defined?(self[sym][i]) ? self[sym][i] : ''}")
        end
      end
    elsif !skip_empty
      %i(container top_container_url barcode location_title location_url).each {|sym| arr.push("#{sym.to_s}:") }
    end

    arr
  end
end
