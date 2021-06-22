# Base class for all renderers
class NoteRenderer
  include ManipulateNode

  def self.inherited(subclass)
    @renderers ||= []
    @renderers << subclass

    subclass.extend(ClassMethods)
  end

  def self.for(type)
    result = @renderers.find {|renderer| renderer.handles_type?(type)}
    unless result
      $stderr.puts "No note renderer for '#{type}'"
      result = UnhandledNoteRenderer
    end

    result.new
  end

  module ClassMethods
    def handles_notes(types)
      @note_types = types
    end

    def handles_type?(type)
      @note_types.include?(type)
    end
  end

  def render(type, note, result)
    # Must fill out note_text and label
    raise "Implement this"
  end

  def render_partial(template, opts = {})
    ApplicationController.new.render_to_string(opts.merge(:partial => 'shared/' + template))
  end

  def build_label(type, note)
    note.has_key?('label') ? note['label'] : I18n.t("enumerations._note_types.#{type}", :default => '')
  end
end


class MultipartNoteRenderer < NoteRenderer
  handles_notes [
    'note_bioghist',
    'note_general_context',
    'note_legal_status',
    'note_mandate',
    'note_multipart',
    'note_structure_or_genealogy',
  ]

  def render(type, note, result)
    result['label'] = build_label(type, note)

    notes = []
    ASUtils.wrap(note['subnotes']).each do |sub|
      unless sub['publish'] == false
        rendered_subnote = {}
        NoteRenderer.for(sub['jsonmodel_type']).render(sub['jsonmodel_type'], sub, rendered_subnote)

        notes << rendered_subnote['note_text']
        result['subnotes'] ||= []
        result['subnotes'] << sub.merge({
                                          '_text' => rendered_subnote['note_text'],
                                          '_title' => sub['title']
                                        })
      end
    end

    result['note_text'] = notes.join('<br/>')
    result
  end
end


class SinglepartNoteRenderer < NoteRenderer
  handles_notes [
    'note_abstract',
    'note_digital_object',
    'note_langmaterial',
    'note_singlepart',
    'note_text',
  ]

  def render(type, note, result)
    result['label'] = build_label(type, note)
    result['note_text'] = ASUtils.wrap(note['content']).map { |s| "<p>#{process_mixed_content(s)}</p>" }.join.html_safe
    result
  end
end


class ERBNoteRenderer < NoteRenderer
  handles_notes [
    'note_bibliography',
    'note_citation',
    'note_chronology',
    'note_definedlist',
    'note_index',
    'note_orderedlist',
    'note_outline',
  ]

  def render(type, note, result)
    result['label'] = build_label(type, note)
    result['note_text'] = render_partial(type, :locals => {:note => note})
    result
  end
end

class UnhandledNoteRenderer < NoteRenderer
  handles_notes []

  def render(type, note, result)
    {'label' => '', 'note_text' => ''}
  end
end
