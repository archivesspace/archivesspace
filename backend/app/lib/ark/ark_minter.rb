require 'digest'

class ArkMinter

  # FIXME: doc
  def mint!(obj, external_ark_url, row_defaults)
    raise NotImplementedError.new
  end

  # Return true if the provided ark name still looks right.  Reasons it might not
  # look right include: changed NAAN, changed repository prefix.  Stuff like that.
  #
  # The `version_key` column in the ark_name table can be used to hold a
  # minter-specific value to record the conditions under which each Ark was
  # generated.  For example, the default minter (archivesspace_ark_minter.rb)
  # stores a hash containing the Ark NAAN & repository prefix that were in use at
  # the point each Ark was generated.  Its `is_still_current?` can then
  # recalculate that hash (using `generate_version_key` below) to determine if the
  # Ark needs to be recomputed.
  def is_still_current?(ark_name_obj, repo_id)
    raise NotImplementedError
  end

  def self.generate_version_key(*version_grist)
    Digest::SHA256.hexdigest(version_grist.map(&:to_s).to_json)
  end

  # Caching prefix lookup for bulk record creation (like imports)
  def prefix_for_repo(repo_id)
    if RequestContext.get(:repo_ark_prefixes).nil?
      RequestContext.put(:repo_ark_prefixes, {})
    end

    prefixes = RequestContext.get(:repo_ark_prefixes)

    if !prefixes.include?(repo_id)
      DB.open do |db|
        prefixes[repo_id] = db[:repository].filter(:id => repo_id).get(:ark_prefix)
      end
    end

    prefixes[repo_id]
  end

end
