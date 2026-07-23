// The IIIF viewer iframe sits inside a File Version subrecord, which starts
// collapsed. Universal Viewer sizes itself from its own iframe viewport as it
// loads and only remeasures on a window resize, so an iframe loaded while
// hidden initialises at zero height and stays blank once the subrecord is
// opened. Hold the src back until the iframe has a size to load into.
$(function () {
  const viewerUrl = function (src) {
    if (!src) {
      return null;
    }

    let url;

    try {
      url = new URL(src, window.location.href);
    } catch {
      return null;
    }

    return url.protocol === 'http:' || url.protocol === 'https:'
      ? url.href
      : null;
  };

  const loadViewer = function (iframe) {
    const $iframe = $(iframe);
    const url = viewerUrl($iframe.attr('data-iiif-src'));

    if (url) {
      $iframe.removeAttr('data-iiif-src');
      $iframe.attr('src', url);
    }
  };

  $(document).on('shown.bs.collapse', function (event) {
    $(event.target)
      .find('iframe[data-iiif-src]')
      .each(function () {
        loadViewer(this);
      });
  });

  // Anything already on screen isn't waiting on a subrecord to be opened.
  $('iframe[data-iiif-src]:visible').each(function () {
    loadViewer(this);
  });
});
