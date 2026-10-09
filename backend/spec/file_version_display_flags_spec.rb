require 'spec_helper'
require_relative '../../common/db/migrations/utils'

# Covers the migration helper that sets the display flags from existing file versions (migration 180).
# The file versions here are database rows from before that migration, so they still have the old
# `is_representative` column, which the migration reads and then drops.
describe 'FileVersionDisplayFlags' do
  let(:enum_ids) {
    {
      :image_thumbnail => 1,
      :text_json => 2,
      :embed => 3,
      :iiif => 4,
      :images => [5, 6],
    }
  }
  let(:new_window) { 7 }
  let(:pdf) { 8 }

  def file_version(id, opts = {})
    {
      :id => id,
      :file_uri => "http://example.com/#{id}",
      :publish => 1,
      :is_representative => nil,
      :use_statement_id => nil,
      :xlink_show_attribute_id => nil,
      :file_format_name_id => nil,
    }.merge(opts)
  end

  def iiif_manifest(id, opts = {})
    file_version(id, { :file_format_name_id => enum_ids[:iiif], :use_statement_id => enum_ids[:text_json],
                       :xlink_show_attribute_id => enum_ids[:embed] }.merge(opts))
  end

  def choose(*file_versions)
    thumbnail, link = FileVersionDisplayFlags.choose(file_versions, enum_ids)
    [thumbnail && thumbnail[:id], link && link[:id]]
  end

  describe 'display thumbnail' do
    it 'is the file version marked representative' do
      expect(choose(file_version(1, :use_statement_id => enum_ids[:image_thumbnail]),
                    file_version(2, :is_representative => 1)).first).to eq(2)
    end

    it 'is else the image-thumbnail file version' do
      expect(choose(file_version(1, :xlink_show_attribute_id => enum_ids[:embed]),
                    file_version(2, :use_statement_id => enum_ids[:image_thumbnail])).first).to eq(2)
    end

    it 'is else an embedded http(s) file version' do
      expect(choose(file_version(1, :file_format_name_id => enum_ids[:images].first),
                    file_version(2, :file_uri => 'https://example.com/2', :xlink_show_attribute_id => enum_ids[:embed])).first).to eq(2)
    end

    it 'is else a jpeg or gif file version' do
      expect(choose(file_version(1, :file_format_name_id => pdf),
                    file_version(2, :file_format_name_id => enum_ids[:images].last)).first).to eq(2)
    end

    it 'is the first file version of the best tier' do
      expect(choose(file_version(1, :file_format_name_id => enum_ids[:images].first),
                    file_version(2, :file_format_name_id => enum_ids[:images].first)).first).to eq(1)
    end

    it 'is never an unpublished file version' do
      expect(choose(file_version(1, :is_representative => 1, :publish => 0),
                    file_version(2, :file_format_name_id => enum_ids[:images].first)).first).to eq(2)
    end

    it 'is not an embedded IIIF manifest' do
      expect(choose(iiif_manifest(1)).first).to be_nil
    end

    it 'is a IIIF manifest marked representative, as before' do
      expect(choose(iiif_manifest(1, :is_representative => 1)).first).to eq(1)
    end

    it 'is nothing when no published file version matches a rule' do
      expect(choose(file_version(1, :xlink_show_attribute_id => new_window, :file_format_name_id => pdf),
                    file_version(2, :is_representative => 1, :publish => 0)).first).to be_nil
    end
  end

  describe 'display link' do
    it 'is the published file version following the display thumbnail' do
      expect(choose(file_version(1), file_version(2, :is_representative => 1), file_version(3), file_version(4))).to eq([2, 3])
    end

    it 'is nothing when the file version following the display thumbnail is unpublished' do
      expect(choose(file_version(1, :is_representative => 1), file_version(2, :publish => 0), file_version(3))).to eq([1, nil])
    end

    it 'is nothing when the display thumbnail is the last file version' do
      expect(choose(file_version(1), file_version(2, :is_representative => 1))).to eq([2, nil])
    end

    context 'without a display thumbnail' do
      it 'is the last published http(s) or data: file version that is not embedded' do
        expect(choose(file_version(1, :xlink_show_attribute_id => new_window),
                      file_version(2, :file_uri => 'data:abc'),
                      file_version(3, :publish => 0),
                      file_version(4, :file_uri => 'not-a-link'))).to eq([nil, 2])
      end

      it 'is not an embedded file version, such as a IIIF manifest' do
        expect(choose(file_version(1), iiif_manifest(2))).to eq([nil, 1])
      end

      it 'is nothing when no file version is a link' do
        expect(choose(file_version(1, :file_uri => 'not-a-link'), file_version(2, :publish => 0))).to eq([nil, nil])
      end
    end

    it 'ignores surrounding whitespace in the file URI' do
      expect(choose(file_version(1, :file_uri => '  http://example.com/1  '))).to eq([nil, 1])
    end
  end

  describe 'enum_ids' do
    def enum_value_id(enum_name, value)
      BackendEnumSource.id_for_value(enum_name, value)
    end

    it 'looks up the enumeration value ids' do
      DB.open do |db|
        expect(FileVersionDisplayFlags.enum_ids(db)).to eq(
          :image_thumbnail => enum_value_id('file_version_use_statement', 'image-thumbnail'),
          :text_json => enum_value_id('file_version_use_statement', 'text-json'),
          :embed => enum_value_id('file_version_xlink_show_attribute', 'embed'),
          :iiif => enum_value_id('file_version_file_format_name', 'iiif'),
          :images => [enum_value_id('file_version_file_format_name', 'jpeg'),
                      enum_value_id('file_version_file_format_name', 'gif')]
        )
      end
    end

    it 'gives -1 for editable enumeration values that have been deleted' do
      DB.open do |db|
        # Renaming the values stands in for deleting them; the spec's transaction rolls it back
        enumeration_ids = db[:enumeration].filter(:name => ['file_version_use_statement', 'file_version_file_format_name']).select(:id)
        db[:enumeration_value]
          .filter(:enumeration_id => enumeration_ids, :value => ['image-thumbnail', 'jpeg', 'gif'])
          .update(:value => Sequel.function(:concat, :value, '-deleted'))

        ids = FileVersionDisplayFlags.enum_ids(db)

        expect(ids[:image_thumbnail]).to eq(-1)
        expect(ids[:images]).to eq([-1, -1])
        expect(ids[:text_json]).to eq(enum_value_id('file_version_use_statement', 'text-json'))
      end
    end
  end
end
