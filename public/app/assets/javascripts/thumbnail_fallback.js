// A thumbnail image failed to load: show the next fallback image of the thumbnail, loading it now, or
// when there is none, the generic icon of the first image in place of the images (ANW-3089)
// Called from the onerror attribute of the thumbnail images
// eslint-disable-next-line no-unused-vars
function showNextThumbnailCandidate(image) {
  const candidate = image.closest('.pui-thumbnail-candidate');
  const next = candidate.nextElementSibling;

  image.style.display = 'none';
  candidate.style.display = 'none';

  if (next && next.classList.contains('pui-thumbnail-candidate')) {
    const nextImage = next.querySelector('img');
    nextImage.src = nextImage.dataset.src;
    next.style.display = 'block';
  } else {
    const first = image
      .closest('.pui-thumbnail')
      .querySelector('.pui-thumbnail-candidate');
    first.style.display = 'block';
    first.querySelector('.pui-thumbnail-fallback').style.display = 'block';
  }
}
