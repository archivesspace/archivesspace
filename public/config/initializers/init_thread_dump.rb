# JRuby 9.3.0.0 introduced more nuanced thread teardowns.
# See: https://github.com/jruby/jruby/pull/6176
# Under the assumption that the thread dump facility is not widely
# relied-upon, we hereby comment it out...
# require 'archivesspace_thread_dump'
# ArchivesSpaceThreadDump.init(File.join(ASUtils.find_base_directory, "thread_dump_pui.txt"))
