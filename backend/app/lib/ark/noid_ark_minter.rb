require 'noid'

class NoidArkMinter < ArkMinter

  def mint!(obj, row_defaults)
    DB.open do |db|
      ark_shoulder = shoulder_for_repo(obj.repo_id)
      ark_template = template_for_repo(obj.repo_id)

      generated_ark = build_generated_ark(obj.repo_id, ark_shoulder, ark_template)
      if generated_ark
        db[:ark_name].insert(row_defaults.merge(:ark_value => generated_ark))
      end
    end
  end

  def ark_recognized?(ark, obj)
    recognized = False
    match = ark.match(%r{/ark:/#{AppConfig[:ark_naan]}/(.*)})
    if match && match.length() > 1
      ark_shoulder = shoulder_for_repo(obj.repo_id)
      ark_template = template_for_repo(obj.repo_id)

      template = Noid::Template.new(ark_shoulder + ark_template)
      recognized = template.valid?(match[1])
    end
    recognized
  end

  private

  def build_generated_ark(repo_id, ark_shoulder, ark_template)
    minter = read_minter_state(repo_id, ark_template)
    if minter == nil
      # att: ignores AppConfig[:ark_shoulder_delimiter] setting
      minter = Noid::Minter.new(template: ark_shoulder + ark_template)
    end
    # this raises an exception if the sequence pool is exhausted
    # we might want to check this and do something about it
    ark_id = minter.mint
    write_minter_state(repo_id, ark_template, minter.dump)
    "ark:/#{AppConfig[:ark_naan]}/#{ark_id}"
  end

  def read_minter_state(repo_id, template)
    DB.open do |db|
      minter = nil
      entry = db[:ark_minter].filter(:repository => repo_id).first
      if entry
        # only return minter if templates match
        if entry[:template] == template
          state = Marshal.load(entry[:state].unpack("m*").first)
          minter = Noid::Minter.new(state)
        end
      end
      minter
    end
  end

  def write_minter_state(repo_id, template, state)
    DB.open do |db|
      puts "write Minter state #{state}"
      binary_state = [Marshal.dump(state)].pack("m*")
      entry = db[:ark_minter].filter(:repository => repo_id).first
      unless entry
        db[:ark_minter].insert(:repository => repo_id, :template => template, :state => binary_state)
      else
        db[:ark_minter].filter(:repository => repo_id).update(:template => template, :state => binary_state)
      end
    end
  end

  ArkName.register_minter(:noid_ark_minter, self)
end
