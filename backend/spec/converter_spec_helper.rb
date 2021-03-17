require 'spec_helper'


def convert(path_to_some_xml, import_events = false)
  converter = my_converter.new(path_to_some_xml)

  if import_events
    converter.set_import_events if converter.respond_to?(:set_import_events)
  else
    converter.unset_import_events if converter.respond_to?(:unset_import_events)
  end

  converter.run
  json = JSON(IO.read(converter.get_output_path))

  json
end


def get_tempfile_path(src)
  tmp = ASUtils.tempfile("doc-#{Time.now.to_i}")
  tmp.write(src)
  tmp.flush

  $icky_hack_to_avoid_gc ||= []
  $icky_hack_to_avoid_gc << tmp

  tmp.path
end
