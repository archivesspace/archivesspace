require 'spec_helper'

describe FileVersionView do

  let(:embeddable_properties) do
    { 
      :xlink_actuate_attribute => 'onLoad',
      :xlink_show_attribute => 'embed',
      :file_format_name => 'jpeg',
      :file_uri => 'http://example.com/file.ext'
    }
  end


  it "can give its uri and uri scheme" do
    f1, f2, f3 = ['file:///file/path/file.ext',
                  'http://example.com/file.ext',
                  'https://example.com/file.ext'].map do |uri|
      build(:file_version, embeddable_properties.merge({
                 :file_uri => uri
            }))
    end

    FileVersionView.new(f1).uri.scheme.should eq('file')
    FileVersionView.new(f2).uri.scheme.should eq('http')
    FileVersionView.new(f3).uri.scheme.should eq('https')
  end


  it "tries to embed bitstreams characterized as 'gif' or 'jpeg'" do
    f1, f2 = %w(jpeg gif).map do |format|
      build(:file_version, embeddable_properties.merge({
              :file_format_name => format,
            }))
    end
    FileVersionView.new(f1).embed.should be_true
    FileVersionView.new(f2).embed.should be_true
  end


  it "won't try to embed bitstreams characterized as 'avi'" do
    f1 = build(:file_version, embeddable_properties.merge({
                 :file_format_name => 'onRequest',
               }))

    FileVersionView.new(f1).embed.should be_false
  end


  it "won't try to embed content tagged 'onRequest'" do
    f1 = build(:file_version, embeddable_properties.merge({
                 :xlink_actuate_attribute => 'onRequest',
               }))

    FileVersionView.new(f1).embed.should be_false
  end


  it "won't try to embed a file unless it has an http or https uri" do
    f = build(:file_version, embeddable_properties.merge({
                :file_uri => "file:///foo/bar.ext"
                                                         }))
    FileVersionView.new(f).embed.should be_false
  end


  it "won't try to embed a file unless 'xlink_show' is set to 'embed'" do
    ["new", "replace", "other", "none"].each do |not_embed|
      f = build(:file_version, embeddable_properties.merge({
                :xlink_show_attribute => not_embed
                                                           }))

      FileVersionView.new(f).embed.should be_false
    end
  end


  it "won't try to embed a file over 500KB in size" do
    f1, f2, f3 = [512000, 512001, nil].map do |bs|
      build(:file_version, embeddable_properties.merge({
              :file_size_bytes => bs
            }))
    end

    FileVersionView.new(f1).embed.should be_true
    FileVersionView.new(f2).embed.should be_false
    FileVersionView.new(f3).embed.should be_true
  end


  it "maps to an embedding template by type" do
    f = build(:file_version, embeddable_properties)
    FileVersionView.new(f).embed_type.should eq(:image)
  end
end
