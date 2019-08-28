#!/bin/bash

# Yeah, I'm really just amusing myself at this point...
export SCRIPT="$0"

"`dirname "$0"`"/../scripts/jruby <(awk '/^### RUBY ###/,EOF' "$0") ${1+"$@"}
exit


### RUBY ###

require 'shellwords'

PLUGINS = [
  {
    :path => 'plugins/series_system',
    :url => 'https://github.com/hudmol/series_system.git',
  },
  {
    :path => 'plugins/as_history',
    :url => 'https://github.com/hudmol/as_history.git',
  },
  {
    :path => 'plugins/qsa_theme',
    :url => 'https://github.com/hudmol/qsa_theme.git',
  },
  {
    :path => 'plugins/in_a_rush',
    :url => 'https://github.com/marktriggs/in_a_rush.git',
  },
  {
    :path => 'plugins/as_mogwai',
    :url => 'https://github.com/hudmol/as_mogwai.git',
  },
  {
    :path => 'plugins/as_runcorn',
    :url => 'https://github.com/hudmol/as_runcorn.git',
  },
  {
    :path => 'plugins/as_reformulator',
    :url => 'https://github.com/hudmol/as_reformulator.git',
  },
  {
    :path => 'plugins/as_cartography',
    :url => 'https://github.com/hudmol/as_cartography.git',
  },
  {
    :path => 'plugins/qsa_kitchensink',
    :url => 'https://github.com/hudmol/qsa_kitchensink.git',
  },
  {
    :path => 'plugins/qsa_www',
    :url => 'https://github.com/hudmol/qsa_www.git',
  },
  {
    :path => 'plugins/qsa_migration_adapter',
    :url => 'https://github.com/hudmol/qsa_migration_adapter',
  }
]


def git(*args)
  _git(args)
end

def git_quiet(*args)
  _git(args, quiet: true)
end

def git_silent(*args)
  _git(args, quiet: true, echo: false)
end

def _git(args, quiet: false, echo: true)
  cmd = "git " + args.map {|a| Shellwords.escape(a)}.join(' ')

  if quiet
    cmd += " >/dev/null 2>&1"
  end

  if echo
    puts "+++ #{cmd}"
  end

  system(cmd)
end

def determine_target_ref(git_dir, target_ref)
  # If `target_ref` actually exists in git_dir, use it.  Otherwise, we'll fall
  # back to origin/master.

  if git_silent("-C", git_dir, "show-ref", target_ref)
    target_ref
  else
    puts "*** WARNING: No ref found matching '#{target_ref}' in repository #{git_dir}.  Falling back to origin/master"
    'origin/master'
  end
end

def main
  Dir.chdir(File.join(File.dirname(ENV['SCRIPT']), '..'))

  mode = ARGV.shift

  unless ["update", "lose-my-work"].include?(mode)
    puts "Usage:"
    puts ""
    puts "  * #{ENV['SCRIPT']} update [ref]  -- update plugins where a fast-forward merge is possible, cloning as needed."
    puts ""
    puts "  * #{ENV['SCRIPT']} lose-my-work [ref]  -- clean and force update all plugins to `ref` (or to master if `ref` not given.)"
    puts ""
    puts "Remotes will use https by default.  To use SSH instead: export GIT_PINEAPPLES_CLONE_WITH_SSH=1"
    puts ""

    exit
  end

  target_ref = ARGV.shift
  target_ref ||= 'origin/master'

  unless target_ref.include?('/')
    target_ref = 'origin/' + target_ref
  end

  PLUGINS.each do |plugin|
    puts ""
    puts "#" * 70
    puts plugin[:path]
    puts "#" * 70

    if Dir.exist?(plugin[:path])
      ref = determine_target_ref(plugin[:path], target_ref)
      local_branch = ref.split('/')[-1]

      # Update it
      git("-C", plugin[:path], "fetch", "origin", "--tags")

      if mode == 'update'
        unless git_silent("-C", plugin[:path], "show-ref", "refs/heads/#{local_branch}")
          # Create a local branch since we don't already have one
          git_quiet("-C", plugin[:path], "checkout", "-b", local_branch, ref)
        end

        if git("-C", plugin[:path], "checkout", local_branch)
          git("-C", plugin[:path], "merge", "--ff-only", ref) or
            puts "\n*** WARNING: couldn't fast-forward merge from #{ref}.  Doing nothing!\n"
        else
          puts "\n*** WARNING: couldn't switch to local branch '#{local_branch}'"
        end

      elsif mode == 'lose-my-work'
        git("-C", plugin[:path], "reset", "--hard")
        git("-C", plugin[:path], "clean", "-fdx")

        # Try to check out a tracking branch, but fall back to non-tracking if
        # we're going from a tag.
        git_quiet("-C", plugin[:path], "checkout", "-t", "-B", local_branch, ref) or
          git_quiet("-C", plugin[:path], "checkout", "-B", local_branch, ref)
      end
    else
      # Clone
      url = plugin[:url]

      if ENV['GIT_PINEAPPLES_CLONE_WITH_SSH']
        url.gsub!('https://github.com/', 'git@github.com:')
      end

      git("clone", url, plugin[:path]) or
        raise "Failed to clone plugin: #{plugin[:path]}"

      ref = determine_target_ref(plugin[:path], target_ref)
      unless ref == 'origin/master'
        # Check out a local tracking branch if we're working from a branch
        local_branch = ref.split('/')[-1]
        unless git_quiet("-C", plugin[:path], "checkout", "-t", ref)
          # But if that failed (because we're targeting a tag, for example),
          # create a local branch ourselves.  Same deal as above.
          git_quiet("-C", plugin[:path], "checkout", "-b", local_branch, ref) or
            raise "Failed to check out ref: #{ref} for plugin: #{plugin[:path]}"
        end
      end
    end
  end


end


main
