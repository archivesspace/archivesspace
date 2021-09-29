# By providing an implementation of ArkMinter, you can add support for your
# preferred way of generating ARKs.
#
# At a minimum, there are three things to do:
#
#  * Provide a `mint!` method.  This is responsible for inserting a new ARK into
#    the `ark_name` table, and should accept the following arguments:
#
#      - obj :: a Sequel::Model instance of the record we're minting an ARK for.
#          At the time of writing, that's either an Archival Object or a Resource.
#
#      - row_defaults :: the recommended default values for several `ark_name`
#          columns.  You can merge any customized values you like into this set.
#
#  * Give your minter a name, and register it with ArkName like this:
#
#         ArkName.register_minter(:my_new_minter, self)
#
#  * Enable your new minter in your `config.rb` file:
#
#         AppConfig[:ark_minter] = :my_new_minter
#
# You can use the provided minter implementations as examples.  The
# `archivesspace_ark_minter.rb` implements the default ArchivesSpace ARK scheme,
# which generates ARKs using a monotonic counter, while the
# `smithsonian_ark_minter.rb` uses UUIDs.
#
# Minters are free to build ARKs however they like, pulling in data from
# whichever sources make sense.  For example, both provided minters make use of
# a system-wide ARK NAAN value, an (optional) repository-specific value (called
# a "shoulder" in ARK parlance), and a system-wide delimiter.  Custom minters
# might work differently, incorporating data from other records and/or external
# sources.
#
# If any of the values incorporated into ARKs happens to change over time, it
# might be desirable to regenerate all affected ARKs.  The "Generate ARKs in
# Bulk" background job handles this regeneration process, but it needs to know
# which ARKs need regenerating.
#
# To make this possible, ARK minters should include a `version_key` value when
# inserting into `ark_name`.  By default, this value is supplied in the
# `row_defaults` handed to `mint!`, and is computed by hashing together the
# three values mentioned previously (NAAN, shoulder, delimiter).  When the
# "Generate ARKs in Bulk" job runs, it recomputes the version key and only
# regenerates ARKs when it has changed.
#
# If your ARKs incorporate data from other sources, you can provide your own
# implementation of `version_key_for` to make sure ARKs are regenerated at the
# right times.
#

require 'digest'

class ArkMinter

  def mint!(obj, row_defaults)
    raise NotImplementedError.new
  end

  # Return true if the provided ark name still looks right.  Reasons it might not
  # look right include: changed NAAN, changed repository shoulder.  Stuff like that.
  #
  # The `version_key` column in the ark_name table can be used to hold a
  # minter-specific value to record the conditions under which each Ark was
  # generated.  For example, the default minter (archivesspace_ark_minter.rb)
  # stores a hash containing the Ark NAAN & repository shoulder that were in use at
  # the point each Ark was generated.  Its `is_still_current?` can then
  # recalculate that hash (using `generate_version_key` below) to determine if the
  # Ark needs to be recomputed.
  def is_still_current?(ark_name_obj, obj)
    ark_name_obj.version_key == version_key_for(obj)
  end

  # Return an opaque value that captures any values that will be used to generate
  # an ARK for `obj`.  Default implementation just hashes together the bits of
  # data the provided minters use for generating ARKs.
  def version_key_for(obj)
    ArkMinter.generate_version_key(AppConfig[:ark_naan], shoulder_for_repo(obj.repo_id), AppConfig[:ark_shoulder_delimiter])
  end

  # Hash some values together and return a string.
  def self.generate_version_key(*version_grist)
    Digest::SHA256.hexdigest(version_grist.map(&:to_s).to_json)
  end

  # Caching shoulder lookup for bulk record creation (like imports)
  def shoulder_for_repo(repo_id)
    if RequestContext.get(:repo_ark_shoulders).nil?
      RequestContext.put(:repo_ark_shoulders, {})
    end

    shoulders = RequestContext.get(:repo_ark_shoulders)

    if !shoulders.include?(repo_id)
      DB.open do |db|
        shoulders[repo_id] = db[:repository].filter(:id => repo_id).get(:ark_shoulder)
      end
    end

    shoulders[repo_id]
  end

end
