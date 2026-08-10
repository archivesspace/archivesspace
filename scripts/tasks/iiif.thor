require 'thor'
require_relative 'iiif_viewers'

class Iiif < Thor

  desc 'update_mirador', 'update the bundled Mirador IIIF viewer'
  option :version, :required => false, :desc => 'version to install (default: the latest release)'
  def update_mirador
    update(IIIFViewers::MIRADOR)
  end

  desc 'update_uv', 'update the bundled Universal Viewer IIIF viewer'
  option :version, :required => false, :desc => 'version to install (default: the latest release)'
  def update_uv
    update(IIIFViewers::UNIVERSAL_VIEWER)
  end

  private

  def update(viewer)
    version = options[:version].to_s.empty? ? nil : options[:version]

    IIIFViewers.update(viewer, version: version)
  end
end
