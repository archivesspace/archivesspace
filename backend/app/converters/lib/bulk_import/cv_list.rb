require 'pp'
include JSONModel
require_relative "../../../model/backend_enum_source"


JSONModel::init(:allow_other_unmapped => AppConfig[:allow_other_unmapped],
 :enum_source => BackendEnumSource)
Log.error("JSONM initted?")
class CvList
    
  @list = []
  @list_hash = {}
  @which = ''

  def initialize(which)
    @which = which
    begin
      jm = JSONModel.init_args 
      Log.error("jm? #{jm.pretty_inspect}  #{jm.class.name}") 
     rescue Exception => exception
      Log.error("no init_args")
     end
    renew
  end

  def value(label)
    if @list_hash[label]
      v =  @list_hash[label]
    elsif @list.index(label)
      v = label
    end
    raise Exception.new(I18n.t('plugins.aspace-import-excel.error.enum',:label =>label,:which => @which)) if !v
    v
  end

  def length
    @list.length
  end

  def renew
    @list = []
    list_hash = {}
    test = JSONModel::JSONModel(:enumeration).new
    
    Log.error("TEST? #{test.pretty_inspect}")
=begin   
    enums =  JSONModel::JSONModel(:enumeration).all
     enums_list = ASUtils.jsonmodels_to_hashes(enums)
    Log.error(enums_list.pretty_inspect)
 enums_list.each do |enum|
      if enum['name'] == @which
        enum['values'].each do |v|
          if v
            trans = I18n.t("enumerations.#{@which}.#{v}", default: v)
            if !list_hash[trans]
              list_hash[trans] = v
              @list.push v
            else
              Rails.logger.warn(I18n.t('plugins.aspace-import-excel.warn.dup', :which => @which, :trans => trans,  :used => list_hash[trans]))
            end
          end
        end
        break
      end
    end 
=end
    @list_hash = list_hash
  end
end
