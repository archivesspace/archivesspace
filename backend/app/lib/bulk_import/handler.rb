# this is the base class for handling objects that  must be linked to
# Archival Objects, such as Subjects, Top Containers, etc.

# a lot of this is adapted from Hudson Mlonglo's Arrearage plugin:
#https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/master/backend/converters/arrearage_converter.rb

# One of the main differences is that we do lookups against the database for objects (such as agent, subject) that
# might already be in the database
#require_relative 'json_client_mixin'
#include ASpaceImportClient

require_relative "cv_list"
require_relative "bulk_import_mixins"

class Handler
  include JSONModel
  include BulkImportMixins

  DISAMB_STR = " DISAMBIGUATE ME!"

  def initialize(current_user, validate_only = false)
    @current_user = current_user
    @validate_only = validate_only
  end

  def save(obj, model)
    test_exceptions(obj)
    saved = model.create_from_json(obj)
    objs = model.sequel_to_jsonmodel([saved])
    revived = objs.empty? ? nil : objs[0] if !objs.empty?
  end

  # if repo_id is nil, do a global search (subject and agent)
  # this is using   archivesspace/backend/app/models/search.rb
  def search(repo_id, params, sym, type = "", match = "", report = nil)
    obj = nil
    search = nil
    matches = match.split(":")
    # need to add these default-y values to the params
    params[:page_size] = 10
    params[:page] = 1
    params[:sort] = ""
    unless !params[:q]
      params[:q] = "primary_type:#{type} AND #{params[:q]}" if !type.empty?
      params[:q] = "repository:\"/repositories/#{repo_id}\" AND  #{params[:q]}" if repo_id
    end
    begin
      search = Search.search(params, nil)
    rescue Exception => e
      raise e if !e.message.match("<h1>Not Found</h1>")  # global search doesn't handle this gracefully :-(
      search = { "total_hits" => 0 }
    end
    total_hits = search["total_hits"] || 0
    if total_hits == 1 #&& !search['results'].empty? # for some reason, you get a hit of '1' but still have
      obj = ASUtils.json_parse(search["results"][0]["json"])
    elsif total_hits > 1
      if matches.length == 2
        match_ct = 0
        disam = matches[1] + DISAMB_STR
        disam_obj = nil
        search["results"].each do |result|
          # if we have a disambiguate result get it
          if result[matches[0]] == disam
            disam_obj = ASUtils.json_parse(result["json"])
          elsif result[matches[0]] == matches[1]
            match_ct += 1
            obj = ASUtils.json_parse(result["json"])
          end
        end
        # if we have more than one exact match, then return disam_obj if we have one, or bail!
        if match_ct > 1
          if disam_obj
            obj = disam_obj
            report.add_info(I18n.t("bulk_import.warn.disamuse", :what => matches[1], :name => disam)) if !report.nil?
          else
            raise BulkImportDisambigException.new(I18n.t("bulk_import.error.too_many"))
          end
        end
      else
        raise BulkImportDisambigException.new(I18n.t("bulk_import.error.too_many"))
      end
    end
    obj = JSONModel(sym).from_hash(obj) if !obj.nil?
    obj
  end

  # centralize the checking for an already-found object
  def stored(hash, id, key)
    ret_obj = hash.fetch(id, nil) || hash.fetch(key, nil)
  end

  def valid(obj, what, report)
    ret_val = false
    begin
      test_exceptions(obj)
      ret_val = true
    rescue Exception => ex
      raise BulkImportException.new(I18n.t("validation_error", :what => what, :err => ex.message))
    end
    ret_val
  end

  def clear(enum_list)
    enum_list.renew
  end
end
