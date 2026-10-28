// A thumbnail image failed to load: show the next fallback image of the thumbnail, loading it now, or
// when there is none, the generic icon of the first image in place of the images (ANW-3089)
// Called from the onerror attribute of the thumbnail images, and when an image times out
function showNextThumbnailCandidate(image) {
  const candidate = image.closest('.digital-object-thumbnail-candidate');
  const next = candidate.nextElementSibling;

  image.style.display = 'none';
  candidate.style.display = 'none';

  if (next && next.classList.contains('digital-object-thumbnail-candidate')) {
    const nextImage = next.querySelector('img');
    nextImage.src = nextImage.dataset.src;
    next.style.display = 'block';
    abandonThumbnailCandidateAfterTimeout(nextImage);
  } else {
    const first = image
      .closest('.digital-object-thumbnail')
      .querySelector('.digital-object-thumbnail-candidate');
    const fallback = first.querySelector('.digital-object-thumbnail-fallback');
    first.style.display = 'block';
    fallback.style.display = 'block';

    // Without a link of its own, the generic icon links to the file of the image (ANW-3001)
    const fallbackLink = fallback.closest(
      '.digital-object-thumbnail-fallback-link'
    );
    if (fallbackLink) fallbackLink.style.display = '';
  }
}

// Gives up on a thumbnail image the browser has not recognized as an image within the timeout of its
// thumbnail (AppConfig[:thumbnail_image_timeout_seconds]), so that a host that does not answer does not
// leave the thumbnail empty. Removing the src lets the browser cancel the download (ANW-3089).
function abandonThumbnailCandidateAfterTimeout(image) {
  const seconds = Number(
    image.closest('.digital-object-thumbnail').dataset.imageTimeoutSeconds
  );
  if (!seconds) return;

  setTimeout(() => {
    // Loaded, failed (handled by onerror), abandoned already, removed from the page, or recognized
    // as an image (its size is known) and still loading
    if (!image.isConnected || image.complete || image.naturalWidth > 0) return;

    image.onerror = null;
    image.removeAttribute('src');
    showNextThumbnailCandidate(image);
  }, seconds * 1000);
}

// Times the first image of each thumbnail as it is added to the page: with the page, or later, like
// the record pane of the tree
new MutationObserver(mutations => {
  const selector = '.digital-object-thumbnail-candidate img[src]';

  mutations.forEach(mutation => {
    mutation.addedNodes.forEach(node => {
      if (node.nodeType !== Node.ELEMENT_NODE) return;

      if (node.matches(selector)) abandonThumbnailCandidateAfterTimeout(node);
      node
        .querySelectorAll(selector)
        .forEach(abandonThumbnailCandidateAfterTimeout);
    });
  });
}).observe(document.documentElement, { childList: true, subtree: true });
